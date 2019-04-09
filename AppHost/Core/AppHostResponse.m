//
//  MKAppHostResponse.m

//
//  Created by liang on 05/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import "AppHostResponse.h"
#import "AppHostViewController.h"
#import "AppHostViewController+Scripts.h"
#import <objc/runtime.h>

@interface AppHostResponse ()

@property (nonatomic, weak, readwrite) WKWebView *webView;

@property (nonatomic, weak, readwrite) UINavigationController *navigationController;

@property (nonatomic, weak, readwrite) AppHostViewController *appHost;

@end

@implementation AppHostResponse

- (instancetype)initWithAppHost:(AppHostViewController *)appHost
{
    if (self = [self init]) {
        self.webView = appHost.webView;
        self.navigationController = appHost.navigationController;
        self.appHost = appHost;
    }

    return self;
}

- (void)fireCallback:(NSString *)callbackKey param:(NSDictionary *)paramDict
{
    [self.appHost fireCallback:callbackKey param:paramDict];
}

- (void)fire:(NSString *)actionName param:(NSDictionary *)paramDict
{
    [self.appHost fire:actionName param:paramDict];
}

- (void)dealloc
{
    _webView = nil;
    self.navigationController = nil;
    self.appHost = nil;
}

#pragma mark - protocol

- (BOOL)handleAction:(NSString *)action withParam:(NSDictionary *)paramDict callbackKey:(NSString *)callbackKey;
{
    if (action == nil) {
        return false;
    }
    SEL sel = nil;
    if (paramDict == nil || paramDict.allKeys.count == 0) {
        if (callbackKey.length == 0) {
            sel = NSSelectorFromString([NSString stringWithFormat:@"%@", action]);
        } else {
            sel = NSSelectorFromString([NSString stringWithFormat:@"%@WithCallback:", action]);
        }
    } else {
        if (callbackKey.length == 0) {
            sel = NSSelectorFromString([NSString stringWithFormat:@"%@:", action]);
        } else {
            sel = NSSelectorFromString([NSString stringWithFormat:@"%@:callback:", action]);
        }
    }
    
    if (![self respondsToSelector:sel]) {
        return NO;
    }
    [self runSelector:sel withObjects:[NSArray arrayWithObjects:paramDict, callbackKey, nil]];
    return YES;
}

- (id)runSelector:(SEL)aSelector withObjects:(NSArray *)objects {
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:aSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:self];
    [invocation setSelector:aSelector];
    
    NSUInteger i = 1;
    
    if (objects.count) {
        for (id object in objects) {
            id tempObject = object;
            [invocation setArgument:&tempObject atIndex:++i];
        }
    }
    [invocation invoke];
    
    if (methodSignature.methodReturnLength > 0) {
        id value;
        [invocation getReturnValue:&value];
        return value;
    }
    return nil;
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
