//
//  AHDebugServerManager.m
//  AppHost
//
//  Created by liang on 2018/12/29.
//  Copyright © 2018 liang. All rights reserved.
//

#import "AHDebugServerManager.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "AppHostViewController.h"
#import "GCDWebServerURLEncodedFormRequest.h"
#import "AHDebugViewController.h"

@interface AHDebugServerManager () <AHDebugViewDelegate>

@property (nonatomic, strong) dispatch_queue_t logQueue;

@property (nonatomic, strong) UIWindow *debugWindow;

/**
 记录上次拖动的位移，两者做差值，来计算此次拖动的距离。
 */
@property (nonatomic, assign) CGPoint lastOffset;

@property (nonatomic, assign) BOOL isSyncing;

@end

static dispatch_io_t _logFile_io;
static off_t _log_offset = 0;

@implementation AHDebugServerManager {
    GCDWebServer *_webServer;
    NSMutableArray *_eventLogs; // 保存所有 native 向 h5 发送的数据；
}

+ (instancetype)sharedInstance
{
    static AHDebugServerManager *_manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [AHDebugServerManager new];
        _manager.logQueue = dispatch_queue_create("com.effetiveobjectivec.syncQueue", DISPATCH_QUEUE_SERIAL);

    });
    return _manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _eventLogs = [NSMutableArray arrayWithCapacity:10];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestEventOccur:) name:kAppHostInvokeRequestEvent object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseEventOccur:) name:kAppHostInvokeResponseEvent object:nil];
    }
    return self;
}

- (void)requestEventOccur:(NSNotification *)notification
{
    dispatch_async(_logQueue, ^{
        [self->_eventLogs addObject:@{ @"type" : @"callNative", @"value" : notification.object }];
    });
}

- (void)responseEventOccur:(NSNotification *)notification
{
    dispatch_async(_logQueue, ^{
        [self->_eventLogs addObject:@{ @"type" : @"callJS", @"value" : notification.object }];
    });
}

#pragma mark - public
CGFloat kDebugWinInitWidth = 55.f;
CGFloat kDebugWinInitHeight = 46.f;
- (void)showDebugWindow
{
    if (self.debugWindow) {
        return;
    }

    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(AH_SCREEN_WIDTH - 60, 150, kDebugWinInitWidth, kDebugWinInitHeight)];
    AHDebugViewController *vc = [[AHDebugViewController alloc] init];
    vc.debugViewDelegate = self;
    window.rootViewController = vc;
    window.backgroundColor = [UIColor grayColor];
    window.windowLevel = UIWindowLevelStatusBar + 14;
    window.hidden = NO;
    window.clipsToBounds = YES;
    self.debugWindow = window;

    //    // 为 window 增加拖拽功能
    //    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragFpsWin:)]; //创建手势
    //    window.userInteractionEnabled = YES;
    //    [window addGestureRecognizer:pan];
}

- (void)handleDragFpsWin:(UIPanGestureRecognizer *)pan
{
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.lastOffset = CGPointZero;
    }
    // 注意：这里的 offset 是相对于在手势开始之前的位置作为基准，和当前手势做差值得出来的位移
    CGPoint offset = [pan translationInView:self.debugWindow];
    //    SELog(@"drag %@", NSStringFromCGPoint(offset));
    CGRect newFrame = CGRectOffset(self.debugWindow.frame, offset.x - self.lastOffset.x, offset.y - self.lastOffset.y);
    //    SELog(@"drag new %@", NSStringFromCGRect(newFrame));
    self.debugWindow.frame = newFrame;

    self.lastOffset = offset;

    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled || pan.state == UIGestureRecognizerStateFailed) {
        self.lastOffset = CGPointZero;
    }
}
#pragma mark - delegate

- (void)tryExpandWindow:(AHDebugViewController *)viewController
{
    [UIView animateWithDuration:0.4
                     animations:^{
                         self.debugWindow.frame = CGRectMake(0, 150, AH_SCREEN_WIDTH, AH_SCREEN_HEIGHT - 150 - 100);
                     }];
}

- (void)tryCollapseWindow:(AHDebugViewController *)viewController
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.debugWindow.frame = CGRectMake(AH_SCREEN_WIDTH - 60, 150, kDebugWinInitWidth, kDebugWinInitHeight);
                     }];
}

- (void)fetchData:(AHDebugViewController *)viewController completion:(void (^)(NSArray<NSString *> *))completion
{
    [self parseLog:completion];
}
#pragma mark - public

- (void)start
{
    // Create server
    _webServer = [[GCDWebServer alloc] initWithLogServer:kGCDWebServer_logging_enabled];

    NSLog(@"Document = %@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]);

    // Add a handler to respond to GET requests on any URL
    typeof(self) __weak weakSelf = self;
    [_webServer addDefaultHandlerForMethod:@"GET"
                              requestClass:[GCDWebServerRequest class]
                              processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {

                                  NSBundle *bundle = [NSBundle bundleForClass:[weakSelf class]];

                                  NSString *fileName = [request.URL lastPathComponent];

                                  if ([fileName isEqualToString:@"/"]) {
                                      fileName = @"server.html";
                                  }

                                  NSString *contentType = nil;
                                  if ([fileName hasSuffix:@".html"]) {
                                      contentType = @"text/html; charset=utf-8";
                                  } else if ([fileName hasSuffix:@".js"]) {
                                      contentType = @"application/javascript";
                                  } else if ([fileName hasSuffix:@".css"]) {
                                      contentType = @"text/css";
                                  }

                                  NSURL *htmlURL = [[bundle bundleURL] URLByAppendingPathComponent:fileName];

                                  NSString *htmlStr = [NSString stringWithContentsOfURL:htmlURL encoding:NSUTF8StringEncoding error:nil];
                                  if (htmlStr.length > 0) {
                                      //                                      htmlStr = [htmlStr stringByReplacingOccurrencesOfString:@"{{ReactLoopURL}}" withString:@"/react_log.do"];
                                      return [GCDWebServerDataResponse responseWithText:htmlStr contentType:contentType];
                                  }
                                  return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Error </p></body></html>"];

                              }];
    [_webServer addDefaultHandlerForMethod:@"POST"
                              requestClass:[GCDWebServerURLEncodedFormRequest class]
                              processBlock:^GCDWebServerResponse *(GCDWebServerURLEncodedFormRequest *request) {

                                  NSURL *url = request.URL;
                                  NSDictionary __block *result = @{};
                                  if ([url.path hasPrefix:@"/react_log.do"]) {
                                      typeof(weakSelf) __strong strongSelf = weakSelf;
                                      dispatch_sync(strongSelf->_logQueue, ^{
                                          NSMutableArray *logStrs = [NSMutableArray arrayWithCapacity:10];
                                          [strongSelf->_eventLogs enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {

                                              NSError *error;
                                              NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&error];

                                              if (!jsonData) {
                                                  NSLog(@"%s: error: %@", __func__, error.localizedDescription);
                                              } else {
                                                  [logStrs addObject:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
                                              }
                                          }];
                                          result = @{ @"count" : @(strongSelf->_eventLogs.count), @"logs" : logStrs };

                                          [strongSelf->_eventLogs removeAllObjects];
                                      });
                                  } else if ([url.path hasPrefix:@"/command.do"]) {
                                      NSLog(@"command");
                                      NSString *action = [request.arguments objectForKey:@"action"];
                                      NSString *param = [request.arguments objectForKey:@"param"] ?: @"";

                                      NSDictionary *contentJSON = nil;
                                      NSError *contentParseError;
                                      if (param) {
                                          param = [self stringDecodeURIComponent:param];
                                          contentJSON = [NSJSONSerialization JSONObjectWithData:[param dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&contentParseError];
                                      }
                                      if (action.length > 0) {
                                          [[NSNotificationCenter defaultCenter] postNotificationName:kAppHostInvokeDebugEvent object:@{ @"action" : action, @"param" : contentJSON }];
                                      } else {
                                          AHLog(@"command.do arguments error");
                                      }
                                      //
                                  }
                                  return [GCDWebServerDataResponse responseWithJSONObject:@{ @"code" : @"OK", @"data" : result }];

                              }];
    // Start server on port 8080
    [_webServer startWithPort:8989 bonjourName:nil];
    NSURL *_Nullable serverURL = _webServer.serverURL;
    NSLog(@"Visit %@ in your web browser", serverURL);
    
    if (kGCDWebServer_logging_enabled) {
        if (_logFile_io == nil) {
            NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *logFile = [docsdir stringByAppendingPathComponent:GCDWebServer_accessLogFileName];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:logFile]) {
                // 同时设置读取流对象
                dispatch_queue_t dq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                
                _logFile_io = dispatch_io_create_with_path(DISPATCH_IO_RANDOM,
                                                           [logFile UTF8String], // Convert to C-string
                                                           O_RDWR,               // Open for reading
                                                           0,                    // No extra flags
                                                           dq, ^(int error) {
                                                               // Cleanup code for normal channel operation.
                                                               // Assumes that dispatch_io_close was called elsewhere.
                                                               NSLog(@"I am ok ");
                                                           });
            } else {
                NSLog(@"日志文件不存在");
            }
        }
    }
}

- (void)parseLog:(void (^)(NSArray<NSString *> *))completion
{
    if (_logFile_io) {
        if (self.isSyncing) {
            return;
        }
        self.isSyncing = YES;
        
        dispatch_queue_t dq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_io_read(_logFile_io, _log_offset, SIZE_T_MAX, dq, ^(bool done, dispatch_data_t _Nullable data, int error) {
            if (error == 0) {
                // convert
                const void *buffer = NULL;
                size_t size = 0;
                dispatch_data_t new_data_file = dispatch_data_create_map(data, &buffer, &size);
                if (new_data_file && size == 0) { /* to avoid warning really - since dispatch_data_create_map demands we care about the return arg */
                    self.isSyncing = NO;
                    return ;
                }
                _log_offset+=size;

                NSData *nsdata = [[NSData alloc] initWithBytes:buffer length:size];
                NSString *line = [[NSString alloc] initWithData:nsdata encoding:NSUTF8StringEncoding];
                
                if (completion && line.length > 0) {
                    NSArray<NSString *> *lines = [line componentsSeparatedByString:@"\n"];
                    NSMutableArray *newLines = [NSMutableArray arrayWithCapacity:10];
                    [lines enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (obj.length > 0) {
                            [newLines addObject:obj];
                        }
                    }];
                    completion(newLines);
                }
                // clean up
//                free(buffer);
            } else if (error != 0) {
                NSLog(@"出错了");
            }
            
            self.isSyncing = NO;
        });
    }
}


- (NSString *)stringDecodeURIComponent:(NSString *)encoded
{
    NSString *decoded = [encoded stringByRemovingPercentEncoding];
    //    NSLog(@"decodedString %@", decoded);
    return decoded;
}

- (void)stop
{
    [_webServer stop];
}
@end
