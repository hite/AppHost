//
//  MKAppHostResponse.m

//
//  Created by liang on 05/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import "AppHostResponse.h"
#import "AppHostViewController.h"

@interface AppHostResponse ()

@property (nonatomic, weak, readwrite) WKWebView *webview;

@property (nonatomic, weak, readwrite) UINavigationController *navigationController;

@property (nonatomic, weak, readwrite) AppHostViewController *appHost;

@end

@implementation AppHostResponse

- (instancetype)initWithAppHost:(AppHostViewController *)appHost
{
    if (self = [self init]) {
        self.webview = appHost.webview;
        self.navigationController = appHost.navigationController;
        self.appHost = appHost;
    }

    return self;
}

- (void)callbackFunctionOnWebPage:(NSString *)actionName param:(NSDictionary *)paramDict
{
    [self.appHost callbackFunctionOnWebPage:actionName param:paramDict];
}

- (void)sendMessageToWebPage:(NSString *)actionName param:(NSDictionary *)paramDict
{
    [self.appHost sendMessageToWebPage:actionName param:paramDict];
}

- (void)dealloc
{
    self.webview = nil;
    self.navigationController = nil;
    self.appHost = nil;
}

#pragma mark - protocol

- (BOOL)handleAction:(NSString *)actionName withParam:(NSDictionary *)parameter
{
    NSAssert(NO, @"Must implement handleActionFromH5 method");
    return NO;
}

+ (BOOL)isSupportedAction:(NSString *)actionName
{
    NSDictionary *support = [self supportActionList];

    // 如果数值大于0，表示是支持的，返回 YES
    if ([[support objectForKey:actionName] integerValue] > 0) {
        return YES;
    }
    return NO;
}

+ (NSDictionary<NSString *, NSString *> *)supportActionList
{
    NSAssert(NO, @"Must implement handleActionFromH5 method");
    return @{};
}
@end
