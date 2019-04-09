//
//  MKAppHost.h
//
//  Created by liang on 05/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import <Foundation/Foundation.h>

@import WebKit;
@class AppHostViewController;

static NSString *const kAppHostURLScheme = @"apphost";
static NSString *const kAppHostURLProtocal = @"apphost://";
static NSString *const kAppHostURLImageHost = @"image.apphost.hite.me";
static NSString *const kAppHostURLScriptHost = @"js.apphost.hite.me";
static NSString *const kAppHostURLStyleHost = @"css.apphost.hite.me";

#define AppHostURLScriptServer [kAppHostURLProtocal stringByAppendingString:kAppHostURLScriptHost]
#define AppHostURLStyleServer [kAppHostURLProtocal stringByAppendingString:kAppHostURLStyleHost]
#define AppHostURLImageServer [kAppHostURLProtocal stringByAppendingString:kAppHostURLImageHost]

@protocol AppHostProtocol <NSObject>

// 以下为 从AppHostViewController 里获得的 只读类属性
@property (nonatomic, weak, readonly) UINavigationController *navigationController;

@property (nonatomic, weak, readonly) WKWebView *webView;

@property (nonatomic, weak, readonly) AppHostViewController *appHost;

@required

- (instancetype)initWithAppHost:(AppHostViewController *)appHost;

/**
 尝试处理来自 h5 的请求，如果不能处理，则返回 NO。

 @param action h5 的 actionName
 @param paramDict 本次请求的参数
 @param callbackKey js 端匿名回调
 @return YES 表示可以处理，已处理；
 */
- (BOOL)handleAction:(NSString *)action withParam:(NSDictionary *)paramDict callbackKey:(NSString *)callbackKey;

/**
 类方法。表示当前请类型是否支持

 @param actionName action 的名词
 @return YES 表示支持，请注意
 */
+ (BOOL)isSupportedAction:(NSString *)actionName;

/**
 返回接口的支持情况， 申明为类方法是为了用同步的方法 返回给 appHost，作为 JS 的属性。

 @return 形如，
    {
        @"alert": @"1",
        @"confrim": @"1"
    }
 */
+ (NSDictionary<NSString *, NSString *> *)supportActionList;

@end
