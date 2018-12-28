//
//  AppHostViewController.h

//
//  Created by hite on 9/22/15.
//  Copyright © 2015 smilly.co All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppHostProtocol.h"

@import WebKit;

@class AppHostViewController;

/**
 监听 Response 里的事件；
 */
@protocol AppHostViewControllerDelegate <NSObject>

- (void)onResponseEventOccurred:(NSString *)eventName response:(id<AppHostProtocol>)response;

@end

@interface AppHostViewController : UIViewController <WKNavigationDelegate>

@property (nonatomic, copy) NSString *pageTitle;

@property (nonatomic, copy) NSString *url;
/**
 *  右上角的文案
 */
@property (nonatomic, copy) NSString *rightActionBarTitle;

//
@property (nonatomic, strong) WKWebView *webview;

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

// 处理 Response 的事件分发
@property (nonatomic, weak) id<AppHostViewControllerDelegate> appHostDelegate;
//核心的函数分发机制。可以继承，

/**
 是否是被presented
 */
@property (nonatomic, assign) BOOL fromPresented;

/**
 * 核心的h5调用native接口的分发器；
 */
- (void)callNative:(NSString *)action parameter:(NSDictionary *)paramDict;

/**
 *  对应传入了匿名对象的接口的调用
 *
 */
- (void)callbackFunctionOnWebPage:(NSString *)actionName param:(NSDictionary *)paramDict;
/**
 *  对应，监听了事件的接口的调用
 */
- (void)sendMessageToWebPage:(NSString *)actionName param:(NSDictionary *)paramDict;

/**
 加载本地 html 资源，支持发送 xhr 请求

 @param path 打开的文件路径
 @param url 发送 xhr 请求的主域名地址，如 http://qian.163.com
 */
- (void)loadLocalFile:(NSString *)path baseURL:(NSURL *)url;

@end
