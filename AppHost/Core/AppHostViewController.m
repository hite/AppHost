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
#import "AHRequestMediate.h"
#import "AppHostViewController+Utils.h"
#import "AppHostViewController+Scripts.h"
#import "AppHostViewController+Dispatch.h"
#import "AppHostViewController+Progressor.h"
#import "AppHostViewController+Timing.h"

@interface AppHostViewController () <UIScrollViewDelegate, WKUIDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, strong) AHSchemeTaskDelegate *taskDelegate;

@end

static NSString *const kAHScriptHandlerName = @"kAHScriptHandlerName";

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
        [self.view addSubview:self.webView];
        self.webView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
                                                [self.webView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
                                                [self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
                                                [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
                                                [self.webView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor]
         ]];
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

    [self fire:@"pageshow" param:@{ @"url" : urlStr ?: @"null" }];
    // 检查是否有上次遗留下来的进度条,避免 webview 在 tabbar 第一屏时出现进度条残留
    if (self.webView.estimatedProgress >= 1.f) {
        [self stopProgressor];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSString *urlStr = [[self.webView URL] absoluteString];
    if (urlStr.length == 0) {
        urlStr = self.url;
    }
    [self fire:@"pagehide" param:@{ @"url" : urlStr ?: @"null" }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupProgressor];
}

- (void)setUrl:(NSString *)url
{
    _url = url;
    if (kFakeCookieWebPageURLWithQueryString.length > 0 && [AppHostCookie loginCookieHasBeenSynced] == NO) { // 此时需要同步 Cookie，走同步 Cookie 的流程
        //
        NSURL *cookieURL = [NSURL URLWithString:kFakeCookieWebPageURLWithQueryString];
        NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:cookieURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:120];
        WKWebView *cookieWebview = [self getCookieWebview];
        [self.view addSubview:cookieWebview];
        [self mark:kAppHostTimingLoadRequest];
        [cookieWebview loadRequest:mutableRequest];
    } else {
        [self loadWebPageWithURL];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[AHWebViewScrollPositionManager sharedInstance] clearAllCache];
}

- (void)dealloc
{
    [self teardownProgressor];
    //
    [_webView.configuration.userContentController removeScriptMessageHandlerForName:kAHScriptHandlerName];

    _webView.navigationDelegate = nil;
    _webView.scrollView.delegate = nil;
    [_webView stopLoading];
    [_webView removeFromSuperview];
    _webView = nil;
    AHLog(@"AppHostViewController dealloc");
}

#pragma mark - public
//https://stackoverflow.com/questions/49826107/wkwebview-custom-url-scheme-doesnt-work-with-https-mixed-content-blocked
- (void)loadLocalFile:(NSURL *)url domain:(NSString *)domain;
{
    NSError *err;
    NSStringEncoding encoding = NSUTF8StringEncoding;
    NSString *content = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:&err];
    
    if (err == nil && content.length > 0 && domain.length > 0) {
        [self mark:kAppHostTimingLoadRequest];
        [self.webView loadHTMLString:content baseURL:[NSURL URLWithString:domain]];
    } else {
        NSAssert(NO, @"加载本地文件出错，关键参数为空");
        AHLog(@"加载本地文件出错，关键参数为空");
    }
}

- (void)loadIndexFile:(NSString *)fileName inDirectory:(NSURL *)directory domain:(NSString *)domain
{
    if (fileName.length == 0 && directory == nil) {
        AHLog(@"文件参数错误");
        return;
    }
    NSString *htmlContent = nil;
    [AHRequestMediate interMediateFile:fileName inDirectory:directory domain:domain output:&htmlContent];
    
    if (htmlContent.length > 0 && domain.length > 0) {
        [self mark:kAppHostTimingLoadRequest];
        [self.webView loadHTMLString:htmlContent baseURL:[NSURL URLWithString:domain]];
    } else {
        NSAssert(NO, @"加载文件夹出错，关键参数为空");
        AHLog(@"加载文件夹出错，关键参数为空");
    }
}

#pragma mark - UI相关
- (void)loadWebPageWithURL
{
    NSURL *url = [NSURL URLWithString:self.url];
    if (url == nil) {
        AHLog(@"loadUrl is nil，loadUrl = %@", self.url);
        [self showTextTip:@"地址为空"];
        return;
    }
    //检查网络是否联网；
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    if ([reachability isReachable]) {
        NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120];
        [self mark:kAppHostTimingLoadRequest];
        [self.webView loadRequest:mutableRequest];
    } else {
        [self showTextTip:@"网络断开了，请检查网络。" hideAfterDelay:10.f];
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

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - wkwebview navigation delegate

#define TIMING_WK_METHOD \
NSLog(@"[Timing] %@, nowTime = %f", NSStringFromSelector(_cmd), [[NSDate date] timeIntervalSince1970] * 1000);

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    TIMING_WK_METHOD
    [self measure:kAppHostTimingDecidePolicyForNavigationAction to:kAppHostTimingLoadRequest];
    [self measure:kAppHostTimingDecidePolicyForNavigationAction to:kAppHostTimingWebViewInit];

    NSURLRequest *request = navigationAction.request;
    //此url解析规则自己定义
    NSString *rurl = [[request URL] absoluteString];
    AHLog(@"加载网页地址 = %@", rurl);
    WKNavigationActionPolicy policy = WKNavigationActionPolicyAllow;

    if ([self isItmsAppsRequest:rurl]) {
        // URL Scheme and App Store links won't work https://github.com/ShingoFukuyama/WKWebViewTips#url-scheme-and-app-store-links-wont-work
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(popOutImmediately) userInfo:nil repeats:NO];
        [[UIApplication sharedApplication] openURL:[request URL] options:@{} completionHandler:nil];
        policy = WKNavigationActionPolicyCancel;
    } else if ([self isExternalSchemeRequest:rurl]) { // 非 http，https 协议的请求，走默认逻辑，容许广告页面之间唤起响应的 App
        [[UIApplication sharedApplication] openURL:[request URL] options:@{} completionHandler:nil];
        policy = WKNavigationActionPolicyCancel;
    }
    //
    decisionHandler(policy);
    if (self.disabledProgressor) {
        self.progressorView.hidden = YES;
    } else if(policy == WKNavigationActionPolicyAllow){
        [self startProgressor];
    }
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    TIMING_WK_METHOD
    [self startProgressor];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(nonnull WKNavigationResponse *)navigationResponse decisionHandler:(nonnull void (^)(WKNavigationResponsePolicy))decisionHandler
{
    TIMING_WK_METHOD
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    TIMING_WK_METHOD
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    TIMING_WK_METHOD
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    TIMING_WK_METHOD
    [self measure:kAppHostTimingDidFinishNavigation to:kAppHostTimingLoadRequest];
    [self measure:kAppHostTimingDidFinishNavigation to:kAppHostTimingWebViewInit];
    
    if (webView.isLoading) {
        return;
    }
    NSURL *targetURL = webView.URL;
    // 如果是指明了 kFakeCookieWebPageURLWithQueryString 说明，需要同步此域下 Cookie；
    if (kFakeCookieWebPageURLWithQueryString.length > 0 && targetURL.query.length > 0 && [kFakeCookieWebPageURLWithQueryString containsString:targetURL.query]) {
        if ([AppHostCookie loginCookieHasBeenSynced] == NO) {
            [AppHostCookie setLoginCookieHasBeenSynced:YES];
            // 加载真正的页面；此时已经有 App 的 cookie 存在了。
            [webView removeFromSuperview];
        }
        [self loadWebPageWithURL];
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

    [self fire:@"onready" param:@{}];
    [self dealWithViewHistory];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    TIMING_WK_METHOD
    [self stopProgressor];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    TIMING_WK_METHOD
    AHLog(@"load page error = %@", error);
    [self stopProgressor];
}

#pragma mark -
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:kAHScriptHandlerName]) {
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
        [self mark:kAppHostTimingWebViewInit];
        WKUserContentController *userContentController = [WKUserContentController new];
        [userContentController addScriptMessageHandler:[[AHScriptMessageDelegate alloc] initWithDelegate:self] name:kAHScriptHandlerName];
        WKWebViewConfiguration *webViewConfig = [[WKWebViewConfiguration alloc] init];
        webViewConfig.userContentController = userContentController;
        webViewConfig.allowsInlineMediaPlayback = YES;
        webViewConfig.processPool = [AppHostCookie sharedPoolManager];
        [webViewConfig setURLSchemeHandler:self.taskDelegate forURLScheme:kAppHostURLScheme];
        [self injectScriptsToUserContent:userContentController];
        [self measure:kAppHostTimingAddUserScript to:kAppHostTimingWebViewInit];

        WKWebView *webview = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webViewConfig];
        webview.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
 
        webview.navigationDelegate = self;
        webview.UIDelegate = self;
        webview.scrollView.delegate = self;
   
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
