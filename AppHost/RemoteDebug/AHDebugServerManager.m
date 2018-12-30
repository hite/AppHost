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

@interface AHDebugServerManager()

@property (nonatomic,strong) dispatch_queue_t logQueue;

@end

@implementation AHDebugServerManager
{
    GCDWebServer* _webServer;
    NSMutableArray *_eventLogs;// 保存所有 native 向 h5 发送的数据；
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

- (void)requestEventOccur:(NSNotification*)notification
{
    dispatch_async(_logQueue, ^{
        [self->_eventLogs addObject:notification.object];
    });
}

- (void)responseEventOccur:(NSNotification*)notification
{
    dispatch_async(_logQueue, ^{
        [self->_eventLogs addObject:notification.object];
    });
}

#pragma mark - public
- (void)start
{
    // Create server
    _webServer = [[GCDWebServer alloc] init];
    
    // Add a handler to respond to GET requests on any URL
    typeof(self) __weak weakSelf = self;
    [_webServer addDefaultHandlerForMethod:@"GET"
                              requestClass:[GCDWebServerRequest class]
                              processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                  
                                  NSBundle *bundle = [NSBundle bundleForClass:[weakSelf class]];
                                  NSURL *htmlURL = [[bundle bundleURL] URLByAppendingPathComponent:@"server.html"];
                                  
                                  NSString *htmlStr = [NSString stringWithContentsOfURL:htmlURL encoding:NSUTF8StringEncoding error:nil];
                                  if (htmlStr.length > 0) {
//                                      htmlStr = [htmlStr stringByReplacingOccurrencesOfString:@"{{ReactLoopURL}}" withString:@"/react_log.do"];
                                      return [GCDWebServerDataResponse responseWithHTML:htmlStr];
                                  }
                                  return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Error </p></body></html>"];
                                  
                              }];
    [_webServer addDefaultHandlerForMethod:@"POST"
                              requestClass:[GCDWebServerURLEncodedFormRequest class]
                              processBlock:^GCDWebServerResponse *(GCDWebServerURLEncodedFormRequest* request) {
                                  
                                  NSURL *url = request.URL;
                                  NSDictionary __block *result = @{};
                                  if ([url.path hasPrefix:@"/react_log.do"]) {
                                      typeof(weakSelf)__strong strongSelf = weakSelf;
                                      dispatch_sync(strongSelf->_logQueue, ^{
                                          NSMutableArray *logStrs = [NSMutableArray arrayWithCapacity:10];
                                          [strongSelf->_eventLogs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                              
                                              NSError *error;
                                              NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj
                                                                                                 options:NSJSONWritingPrettyPrinted
                                                                                                   error:&error];
                                              
                                              if (! jsonData) {
                                                  NSLog(@"%s: error: %@", __func__, error.localizedDescription);
                                              } else {
                                                  [logStrs addObject: [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
                                              }
                                          }];
                                          result = @{
                                                     @"count":@(strongSelf->_eventLogs.count),
                                                     @"logs": logStrs
                                                     };
                                          
                                          [strongSelf->_eventLogs removeAllObjects];
                                      });
                                  } else if ([url.path hasPrefix:@"/command.do"]) {
                                      NSLog(@"command");
                                      NSString *action = [request.arguments objectForKey:@"action"];
                                      NSString *param = [request.arguments objectForKey:@"param"]?:@"";
                                      
                                      NSDictionary *contentJSON = nil;
                                      NSError *contentParseError;
                                      if (param) {
                                          param = [self stringDecodeURIComponent:param];
                                          contentJSON = [NSJSONSerialization JSONObjectWithData:[param dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&contentParseError];
                                      }
                                      if (action.length > 0) {
                                          [[NSNotificationCenter defaultCenter] postNotificationName:kAppHostInvokeDebugEvent
                                                                                              object:@{
                                                                                                       @"action": action,
                                                                                                       @"param": contentJSON
                                                                                                       }];
                                      } else {
                                          AHLog(@"command.do arguments error");
                                      }
//
                                  }
                                  return [GCDWebServerDataResponse responseWithJSONObject:@{
                                                                                            @"code":@"OK",
                                                                                            @"data":result
                                                                                            }];
                                  
                              }];
    // Start server on port 8080
    [_webServer startWithPort:8080 bonjourName:nil];
    NSURL * _Nullable serverURL = _webServer.serverURL;
    NSLog(@"Visit %@ in your web browser", serverURL);
   
    
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
