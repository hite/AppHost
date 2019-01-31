//
//  AppHostViewController.m

//
//  需要h5和native 相互调用接口 页面使用此viewcontroller。
//
//  Created by hite on 9/22/15.
//  Copyright © 2015 smilly.co All rights reserved.
//

#import "AppHostViewController.h"
#import "Reachability.h"
#import "AHWebViewScrollPositionManager.h"
#import "AHNavigationBarResponse.h"
#import "AHAppLoggerResponse.h"
#import "AppHostCookie.h"
#import "AHScriptMessageDelegate.h"
#import "AHURLChecker.h"
#import "AHResponseManager.h"

@interface AppHostViewController () <UIScrollViewDelegate, WKUIDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) NSTimer *timer;
// 以下是页面加载的进度条
@property (nonatomic, strong) NSTimer *progressorTimer;

@property (nonatomic, strong) NSTimer *clearProgressorTimer;

@property (nonatomic, strong) UIProgressView *progressorView;

@property (nonatomic, assign) BOOL isProgressorDone;

@property (nonatomic, strong) AHSchemeTaskDelegate *taskDelegate;

@end

static NSString *const kAHRequestItmsApp = @"itms-apps://";
static NSString *const kAHScriptHandlerName = @"kAHScriptHandlerName";
static NSString *const kAppHostScheme = @"apphost";

// 是否将客户端的 cookie 同步到 WKWebview 的 cookie 当中
// 作为写 cookie 的假地址
NSString *_Nonnull kFakeCookieWebPageURLWithQueryString;
// 以下两个是为了设置进度条颜色和日志开关
long long kWebViewProgressTintColorRGB;
BOOL kGCDWebServer_logging_enabled = YES;

/**
 * 代理类，管理所有 AppHostViewController 自身和 AppHostViewController 子类。
 * 使更具模块化，在保持灵活的同时，也保留了可读性。
 * 整体设计思路是：
 1. 维护了所有可支持 h5 的类名的数组（如[AHLogger]，以及这些类名的实例化的对象)，未使用到的不必实例化，做延迟实例化。
 2. 设计一个 protocol ，所有可支持 h5 的类名 都遵循这一协议。
 */

@implementation AppHostViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 注意：此时还没有 navigationController。
        self.taskDelegate = [AHSchemeTaskDelegate new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(debugCommand:) name:kAppHostInvokeDebugEvent object:nil];
    }

    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSString *urlStr = nil;
    if (self.webView && !self.webView.isLoading) {
        urlStr = [[self.webView URL] absoluteString];
    }
    if (urlStr.length == 0) {
        urlStr = self.url;
    }

    [self sendMessageToWebPage:@"pageshow" param:@{ @"url" : urlStr ?: @"null" }];
    // 检查是否有上次遗留下来的进度条,避免 webview 在 tabbar 第一屏时出现进度条残留
    if (self.webView.estimatedProgress >= 1.f) {
        self.isProgressorDone = YES;
        self.progressorView.hidden = YES;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSString *urlStr = [[self.webView URL] absoluteString];
    if (urlStr.length == 0) {
        urlStr = self.url;
    }
    [self sendMessageToWebPage:@"pagehide" param:@{ @"url" : urlStr ?: @"null" }];

    //
    [self.timer invalidate];
    self.timer = nil;
    [self.progressorTimer invalidate];
    self.progressorTimer = nil;
    [self.clearProgressorTimer invalidate];
    self.clearProgressorTimer = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initViews];
}

- (void)initViews
{
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.webView];
    //
    AHLog(@"load urltext: %@", self.url);

    NSURL *actualUrl = [NSURL URLWithString:self.url];
    if (actualUrl == nil) {
        AHLog(@"loadUlr 异常 = %@", self.url);
        return;
    }
    // 添加url加载进度条。
    [self addWebviewProgressor];

    if (kFakeCookieWebPageURLWithQueryString.length > 0 && [AppHostCookie loginCookieHasBeenSynced] == NO) { // 此时需要同步 Cookie，走同步 Cookie 的流程
        //
        NSURL *cookieURL = [NSURL URLWithString:kFakeCookieWebPageURLWithQueryString];
        NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:cookieURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120];
        WKWebView *cookieWebview = [self getCookieWebview];
        [self.view addSubview:cookieWebview];
        [cookieWebview loadRequest:mutableRequest];
        AHLog(@"preload cookie for url = %@", self.url);
    } else {
        [self loadWebPage];
    }
}

- (void)addWebviewProgressor
{
    // 仿微信进度条
    self.progressorView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, AH_NAVIGATION_BAR_HEIGHT, AH_SCREEN_WIDTH, 20.0f)];
 
    self.progressorView.progressTintColor = kWebViewProgressTintColorRGB > 0? AHColorFromRGB(kWebViewProgressTintColorRGB):[UIColor grayColor];
    self.progressorView.trackTintColor = [UIColor whiteColor];
    [self.view addSubview:self.progressorView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[AHWebViewScrollPositionManager sharedInstance] clearAllCache];
}

- (void)dealloc
{
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:kAHScriptHandlerName];

    self.webView.navigationDelegate = nil;
    self.webView.scrollView.delegate = nil;
    [self.webView stopLoading];
    [self.webView removeFromSuperview];
    self.webView = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAppHostInvokeDebugEvent object:nil];
    
    AHLog(@"AppHostViewController dealloc");
}

#pragma mark - public

- (void)loadLocalFile:(NSURL *)url domain:(NSString *)domain;
{
    NSError *err;
    NSStringEncoding encoding = NSUTF8StringEncoding;
    NSString *content = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:&err];
    if (err == nil && content.length > 0 && domain.length > 0) {
        [self.webView loadHTMLString:content baseURL:[NSURL URLWithString:domain]];
    } else {
        NSAssert(NO, @"加载本地文件出错，关键参数为空");
        AHLog(@"加载本地文件出错，关键参数为空");
    }
}

- (void)loadHTML:(NSString *)fileName inDirectory:(NSURL *)directory domain:(NSString *)baseDomain
{
    // 实现方式是；将这些文件合并为新的 HTML，css 和 js 都作为内联的 script 和 style；
    // 先把 filename 读出来，作为一个 ast，分析到相对 css、js，填充到新的 HTML 里
}
#pragma mark - UI相关

- (void)loadWebPage
{
    NSURL *url = [NSURL URLWithString:self.url];
    if (url == nil) {
        NSLog(@"loadUrl is nil，loadUrl = %@", self.url);
        [self showTextTip:@"地址为空"];
        return;
    }
    //检查网络是否联网；

    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    if ([reachability isReachable]) {
        //
        NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120];
        [self.webView loadRequest:mutableRequest];
    } else {
        [self showTextTip:@"网络断开了，请检查网络。" hideAfterDelay:10.f];
    }
}

#pragma mark - shim

- (void)showTextTip:(NSString *)text
{
    [self showTextTip:text hideAfterDelay:2.f];
}

- (void)showTextTip:(NSString *)text hideAfterDelay:(CGFloat)delay
{
    [self callNative:@"showTextTip" parameter:@{
                                                @"text" : text ?: @"<空>",
                                                @"hideAfterDelay" : @(delay > 0 ?: 2.f)
                                                }];
}

#pragma mark - core
- (void)dispatchParsingParameter:(NSDictionary *)contentJSON
{
    NSMutableDictionary *paramDict = [[contentJSON objectForKey:@"param"] mutableCopy];

    // 增加对异常参数的catch
    @try {
        [self callNative:[contentJSON objectForKey:@"action"] parameter:paramDict];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kAppHostInvokeRequestEvent object:contentJSON];
    } @catch (NSException *exception) {
        [self showTextTip:@"H5接口异常"];
        AHLog(@"h5接口解析异常，接口数据：%@", contentJSON);
    } @finally {
    }
}

// 延迟初始化； 短路判断
- (BOOL)callNative:(NSString *)action parameter:(NSDictionary *)paramDict
{
    id<AppHostProtocol> vc = [[AHResponseManager defaultManager] responseForAction:action withAppHost:self];
    //
    if (vc == nil) {
        NSString *errMsg = [NSString stringWithFormat:@"action (%@) not supported yet.", action];
        AHLog(@"action (%@) not supported yet.", action);
        [self sendMessageToWebPage:@"NotSupported" param:@{
                                                  @"error": errMsg
                                                  }];
        return NO;
    } else {
        [vc handleAction:action withParam:paramDict];
        return YES;
    }
}

#pragma mark - wkwebview uidelegate

- (WKWebView *)webView:(WKWebView *)webView
    createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
               forNavigationAction:(WKNavigationAction *)navigationAction
                    windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    NSLog(@"%@", NSStringFromSelector(_cmd));
    return nil;
}

#pragma mark - scrollview delegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.disableScrollPositionMemory) {
        return;
    }
    CGFloat y = scrollView.contentOffset.y;
    NSLog(@"contentOffset.y = %.2f", y);
    [[AHWebViewScrollPositionManager sharedInstance] cacheURL:self.webView.URL position:y];
}

#pragma mark - wkwebview ui delegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
    
}
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    //    DLOG(@"msg = %@ frmae = %@",message,frame);
    [webView evaluateJavaScript:@"document.title;" completionHandler:^(NSString *title, NSError * _Nullable error) {
        AHLog(@"34343 %@", title);
    }];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - wkwebview navigation delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSLog(@"%@", NSStringFromSelector(_cmd));

    NSURLRequest *request = navigationAction.request;
    //此url解析规则自己定义
    NSString *rurl = [[request URL] absoluteString];
    WKNavigationActionPolicy policy = WKNavigationActionPolicyAllow;

    if ([self isItmsAppsRequest:rurl]) {
        // 遇到 itms-apps://itunes.apple.com/cn/app/id992055304  主动 pop出去
        // URL Scheme and App Store links won't work https://github.com/ShingoFukuyama/WKWebViewTips#url-scheme-and-app-store-links-wont-work
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(popOutImmediately) userInfo:nil repeats:NO];
        [[UIApplication sharedApplication] openURL:[request URL] options:@{} completionHandler:nil];
        policy = WKNavigationActionPolicyCancel;
    } else if ([self isExternalSchemeRequest:rurl]) {
        [[UIApplication sharedApplication] openURL:[request URL] options:@{} completionHandler:nil];
        policy = WKNavigationActionPolicyCancel;
    }
    //
    decisionHandler(policy);
    
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    AHLog(@"didReceiveServerRedirectForProvisionalNavigation = %@", navigation);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(nonnull WKNavigationResponse *)navigationResponse decisionHandler:(nonnull void (^)(WKNavigationResponsePolicy))decisionHandler
{
    NSURLResponse *resp = navigationResponse.response;
    NSURL *url = [resp URL];
    AHLog(@"navigationResponse.url = %@", url);

    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    AHLog(@"didCommitNavigation = %@", navigation);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    if (self.disabledProgressor) {
        self.progressorView.hidden = YES;
    } else {
        // 清理旧的timer
        [self.progressorTimer invalidate];

        self.progressorView.progress = 0;
        self.isProgressorDone = NO;
        self.progressorView.hidden = NO;
        // 0.01667 is roughly 1/60, so it will update at 60 FPS

        self.progressorTimer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(loadingProgressor) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.progressorTimer forMode:NSRunLoopCommonModes];
    }
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (webView.isLoading) {
        return;
    }

    NSURL *targetURL = webView.URL;
    // 如果是知名了 kFakeCookieWebPageURLWithQueryString 说明，需要同步此域下 Cookie；
    if (kFakeCookieWebPageURLWithQueryString.length > 0 && [AppHostCookie loginCookieHasBeenSynced] == NO && targetURL.query.length > 0 && [kFakeCookieWebPageURLWithQueryString containsString:targetURL.query]) {
        [AppHostCookie setLoginCookieHasBeenSynced:YES];
        // 加载真正的页面；此时已经有 App 的 cookie 存在了。
        [webView removeFromSuperview];
        [self loadWebPage];
        return;
    }

    //如果是全新加载页面，而不是从历史里弹出的情况下，需要渲染导航
    if (![self.webView canGoForward] && self.rightActionBarTitle.length > 0) {
        [self callNative:@"setNavRight" parameter:@{
                                                    @"text":self.rightActionBarTitle
                                                    }];
    }
    [self callNative:@"setNavTitle" parameter:@{
                                                @"text":self.webView.title?:self.pageTitle
                                                }];
    //设置发现的后台接口；
    NSDictionary *inserted = [self supportListByNow];
    [inserted enumerateKeysAndObjectsUsingBlock:^(NSString *keyStr, id obj, BOOL *stop) {
        [self insertData:obj intoPageWithVarName:keyStr];
    }];

    [self sendMessageToWebPage:@"onready" param:@{}];

    self.isProgressorDone = YES;
    // 防止内存飙升
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"WebKitDiskImageCacheEnabled"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"WebKitOfflineWebApplicationCacheEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //
    [self dealWithViewHistory];

    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)dealWithViewHistory
{
    if (self.disableScrollPositionMemory) {
        return;
    }

    NSURL *url = self.webView.URL;
    UIScrollView *sv = self.webView.scrollView;
    CGFloat oldY = [[AHWebViewScrollPositionManager sharedInstance] positionForCacheURL:url];
    if (oldY != sv.contentOffset.y) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            sv.contentOffset = CGPointMake(0, oldY);
        });
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:kAHScriptHandlerName]) {
        //
        NSLog(@"%@", message.body);
        NSURL *actualUrl = [NSURL URLWithString:self.url];
        if (![[AHURLChecker sharedManager] checkURL:actualUrl forAuthorizationType:AHAuthorizationTypeAppHost]) {
            NSLog(@"invalid url visited : %@", self.url);
        } else {
            NSDictionary *contentJSON = message.body;
            [self dispatchParsingParameter:contentJSON];
        }
    } else {
#ifdef DEBUG
        [self showTextTip:@"没有实现的接口"];
#endif
        AHLog(@"unknown methods : %@", message.name);
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    self.isProgressorDone = YES;
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    self.isProgressorDone = YES;
    NSLog(@"%@", NSStringFromSelector(_cmd));
    //    [self showTextTip:@"加载页面内容时出错"];
    AHLog(@"load page error = %@", error);
}

- (void)popOutImmediately
{
    if (self.fromPresented) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)loadingProgressor
{
    //    AHLog(@"progress = %f", self.webview.estimatedProgress);
    if (self.isProgressorDone) {
        [self.progressorView setProgress:1 animated:YES];
        [self.progressorTimer invalidate];
        // 完成之后clear进度
        self.clearProgressorTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(clearProgressor) userInfo:nil repeats:NO];
    } else {
        self.progressorView.progress = self.webView.estimatedProgress;
    }
}

- (void)clearProgressor
{
    self.progressorView.hidden = YES;
    [self.clearProgressorTimer invalidate];
}

#pragma mark - supportType

- (void)executeJavaScriptString:(NSString *)javaScriptString
{
    [self.webView evaluateJavaScript:javaScriptString completionHandler:nil];
}

- (NSDictionary *)supportListByNow
{
    //人肉维护支持列表；
    NSMutableDictionary *supportedFunctions = [@{
        //增加apphost的supportTypeFunction
        @"pageshow" : @"2",
        @"pagehide" : @"2"
    } mutableCopy];
    // 内置接口
    // 各个response 的 supportFunction
    [[AHResponseManager defaultManager].customResponseClasses enumerateObjectsUsingBlock:^(Class resp, NSUInteger idx, BOOL * _Nonnull stop) {
        [supportedFunctions addEntriesFromDictionary:[resp supportActionList]];
    }];


    NSMutableDictionary *lst = [NSMutableDictionary dictionaryWithCapacity:10];
    [lst setObject:supportedFunctions forKey:@"supportFunctionType"];

    NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithCapacity:10];
    if (AH_IS_SCREEN_HEIGHT_X) {
        [appInfo setObject:@{ @"iPhoneXVersion" : @"1" } forKey:@"iPhoneXInfo"];
    }

    [lst setObject:appInfo forKey:@"appInfo"];
    return lst;
}

#pragma mark - debug

- (void)insertData:(NSDictionary *)json intoPageWithVarName:(NSString *)appProperty
{
    NSData *objectOfJSON = nil;
    NSError *contentParseError = nil;

    objectOfJSON = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&contentParseError];
    if (contentParseError == nil && objectOfJSON) {
        NSString *str = [[NSString alloc] initWithData:objectOfJSON encoding:NSUTF8StringEncoding];
        [self executeJavaScriptString:[NSString stringWithFormat:@"if(window.appHost){window.appHost.%@ = %@;}", appProperty, str]];
    }
}



#pragma mark - innner
- (void)debugCommand:(NSNotification *)notif
{
    NSString *action = [notif.object objectForKey:@"action"];
    NSDictionary *param = [notif.object objectForKey:@"param"];
    
    if (action.length > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self callNative:action parameter:param];
        });
    }
}

- (BOOL)isExternalSchemeRequest:(NSString *)url
{
    NSArray<NSString *> *prefixs = @[ @"http://", @"https://"];
    BOOL __block external = YES;

    [prefixs enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([url hasPrefix:obj]) {
            external = NO;
            *stop = YES;
        }
    }];

    return external;
}

- (BOOL)isItmsAppsRequest:(NSString *)url
{
    // itms-appss://itunes.apple.com/cn/app/id992055304
    // https://itunes.apple.com/cn/app/id992055304
    NSArray<NSString *> *prefixs = @[ kAHRequestItmsApp, @"https://itunes.apple.com", @"itms-appss://", @"itms-services://", @"itmss://" ];
    BOOL __block pass = NO;

    [prefixs enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([url hasPrefix:obj]) {
            pass = YES;
            *stop = YES;
        }
    }];

    return pass;
}

- (void)callbackFunctionOnWebPage:(NSString *)actionName param:(NSDictionary *)paramDict
{
    [self __sendMessageToWebPage:actionName funcName:@"__callback" param:paramDict];
}

- (void)sendMessageToWebPage:(NSString *)actionName param:(NSDictionary *)paramDict
{
    [self __sendMessageToWebPage:actionName funcName:@"__fire" param:paramDict];
}

- (void)__sendMessageToWebPage:(NSString *)actionName funcName:(NSString *)funcName param:(NSDictionary *)paramDict
{
    NSData *objectOfJSON = nil;
    NSError *contentParseError;

    objectOfJSON = [NSJSONSerialization dataWithJSONObject:paramDict options:NSJSONWritingPrettyPrinted error:&contentParseError];

    NSString *jsCode = [NSString stringWithFormat:@"window.appHost.%@('%@',%@);", funcName, actionName, [[NSString alloc] initWithData:objectOfJSON encoding:NSUTF8StringEncoding]];
    [self logRequestAndResponse:jsCode type:@"response"];
    jsCode = [jsCode stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    [self executeJavaScriptString:jsCode];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAppHostInvokeResponseEvent object:@{
                                                                                                    @"action": actionName,
                                                                                                    @"param": paramDict
                                                                                                    }];
}

- (void)logRequestAndResponse:(NSString *)str type:(NSString *)type
{
    NSUInteger toIndex = MIN(500, str.length);
    AHLog(@"debug type: %@ , url : %@", type, [str substringToIndex:toIndex]);
}

#pragma mark - getter

- (WKWebView *)getCookieWebview
{
    if (![kFakeCookieWebPageURLWithQueryString containsString:@"?"]) {
        NSAssert(NO, @"请配置 kFakeCookieWebPageURLString 参数，如在调用 AppHostViewController 的 .m 文件里定义，NSString *_Nonnull kFakeCookieWebPageURLWithQueryString = @\"https://www.163.com?028-983cnhd8-2\"");
        return nil;
    }
    // 设置加载页面完毕后，里面的后续请求，如 xhr 请求使用的cookie
    WKUserContentController *userContentController = [WKUserContentController new];

    WKWebViewConfiguration *webViewConfig = [[WKWebViewConfiguration alloc] init];
    webViewConfig.userContentController = userContentController;
    webViewConfig.processPool = [AppHostCookie sharedPoolManager];

    NSMutableArray<NSString *> *oldCookies = [AppHostCookie cookieJavaScriptArray];
    [oldCookies enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSString *setCookie = [NSString stringWithFormat:@"document.cookie='%@';", obj];
        WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:setCookie injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript];
    }];

    WKWebView *webview = [[WKWebView alloc] initWithFrame:CGRectMake(0, -1, AH_SCREEN_WIDTH, 0.1f) configuration:webViewConfig];
    webview.navigationDelegate = self;

    return webview;
}

- (WKWebView *)webView
{
    if (_webView == nil) {
        // 设置加载页面完毕后，里面的后续请求，如 xhr 请求使用的cookie
        WKUserContentController *userContentController = [WKUserContentController new];
        __weak typeof(self) weakSelf = self;
        [userContentController addScriptMessageHandler:[[AHScriptMessageDelegate alloc] initWithDelegate:weakSelf] name:kAHScriptHandlerName];
        WKWebViewConfiguration *webViewConfig = [[WKWebViewConfiguration alloc] init];
        webViewConfig.userContentController = userContentController;
        webViewConfig.allowsInlineMediaPlayback = YES;
        webViewConfig.processPool = [AppHostCookie sharedPoolManager];
        [webViewConfig setURLSchemeHandler:self.taskDelegate forURLScheme:kAppHostScheme];
        
        // 注入关键 js 文件
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSURL *jsLibURL = [[bundle bundleURL] URLByAppendingPathComponent:@"appHost_version_1.5.0.js"];
        
        NSString *jsLib = [NSString stringWithContentsOfURL:jsLibURL encoding:NSUTF8StringEncoding error:nil];
        if (jsLib.length > 0) {
            WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:jsLib injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
            [userContentController addUserScript:cookieScript];
        } else {
            NSAssert(NO, @"主 JS 文件加载失败");
            AHLog(@"Fatal Error: appHost.js is not loaded.");
        }
        
        WKWebView *webview = [[WKWebView alloc] initWithFrame:CGRectMake(0, AH_NAVIGATION_BAR_HEIGHT, AH_SCREEN_WIDTH, AH_SCREEN_HEIGHT - AH_NAVIGATION_BAR_HEIGHT) configuration:webViewConfig];
        webview.scrollView.contentSize = CGSizeMake(CGRectGetWidth(webview.frame), CGRectGetHeight(webview.frame));
        webview.navigationDelegate = self;
        webview.UIDelegate = self;
        webview.scrollView.delegate = self;
        
//        [webview setValue:@(NO) forKey:@"allowsRemoteInspection"];
        
        _webView = webview;
    }
    
    
    return _webView;
}

#pragma mark - vc settings

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.navBarStyle;
}

@end
