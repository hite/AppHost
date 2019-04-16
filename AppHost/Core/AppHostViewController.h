//
//  AppHostViewController.h

//
//  Created by hite on 9/22/15.
//  Copyright © 2015 smilly.co All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppHostProtocol.h"
#import "AHSchemeTaskDelegate.h"
#import "AppHostEnum.h"

static NSString *kAppHostInvokeRequestEvent = @"kAppHostInvokeRequestEvent";
static NSString *kAppHostInvokeResponseEvent = @"kAppHostInvokeResponseEvent";
static NSString *kAppHostInvokeDebugEvent = @"kAppHostInvokeDebugEvent";

@class AppHostViewController;

/**
 监听 Response 里的事件；
 */
@protocol AppHostViewControllerDelegate <NSObject>

- (void)onResponseEventOccurred:(NSString *)eventName response:(id<AppHostProtocol>)response;

@end

@interface AppHostViewController : AH_VC_BASE_NAME <WKNavigationDelegate>

@property (nonatomic, copy) NSString *pageTitle;

/**
 当使用 url 地址加载页面时，url 代表了初始的 url。当载入初始  url 后，页面的地址还可能发生变化，此时不等于此 url。
 */
@property (nonatomic, copy) NSString *url;
/**
 *  右上角的文案
 */
@property (nonatomic, copy) NSString *rightActionBarTitle;

//
@property (nonatomic, strong, readonly) WKWebView *webView;

/**
 定制状态栏的配色
 */
@property (nonatomic, assign) UIStatusBarStyle navBarStyle;
/**
 不容许进度条
 */
@property (nonatomic, assign) BOOL disabledProgressor;

/**
 取消记住上次浏览历史的特性
 */
@property (nonatomic, assign) BOOL disableScrollPositionMemory;
/**
 *  指，当点击导航栏的back按钮时候，执行的跳转，并且这个跳转到这个链接
 */
@property (nonatomic, strong) NSDictionary *backPageParameter;

// 处理 Response 内部发送的事件，这些事件，除了 h5 关心之外，可能 native 本身也很关心
@property (nonatomic, weak) id<AppHostViewControllerDelegate> appHostDelegate;
//核心的函数分发机制。可以继承，

/**
 是否是被presented
 */
@property (nonatomic, assign) BOOL fromPresented;

@property (nonatomic, strong, readonly) AHSchemeTaskDelegate *taskDelegate;

#pragma mark - 使用缓存渲染界面
/**
 加载本地 html 资源，支持发送 xhr 请求

 @param url 打开的文件路径
 @param baseDomain 发送 xhr 请求的主域名地址，如 http://you.163.com
 */
- (void)loadLocalFile:(NSURL *)url domain:(NSString *)baseDomain;

/**
 加载本地文件夹。文件夹只支持 HTML，JS，CSS 文件。
 <b> 在 iOS 11 以上使用 taskscheme，iOS 8+ 以上使用文件合并，不支持本地图片；</b>

 @param fileName 主 HTML 文件的文件名，是个相对路径。 html 文件里应用的内部 js、css 文件都是相对于 directory 参数的
 @param directory 相对路径，包含 HTML，JS，CSS 文件
 @param baseDomain 为了解决相对路径 发送 xhr 请求的主域名地址，如 http://you.163.com
 */
- (void)loadIndexFile:(NSString *)fileName inDirectory:(NSURL *)directory domain:(NSString *)baseDomain;

@end
