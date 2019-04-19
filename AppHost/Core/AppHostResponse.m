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

+ (BOOL)isSupportedActionSignature:(NSString *)signature
{
    NSDictionary *support = [self supportActionList];

    // 如果数值大于0，表示是支持的，返回 YES
    if ([[support objectForKey:signature] integerValue] > 0) {
        return YES;
    }
    return NO;
}

+ (NSDictionary<NSString *, NSString *> *)supportActionList
{
    NSAssert(NO, @"Must implement handleActionFromH5 method");
    return @{};
}
#pragma - doc
/**
 TODO 可变参数如何传参？解决代码copy的问题
 解决生成 ah_doc 的文档里的参数对象
 
 @param desc 默认描述，如果是偶数个参数，则生成 param 对象。如果是单个参数则认为整体参数描述，不细分为小参数
 @return 返回一个字段对象
 */
+ (NSDictionary *)getParams:(NSString *)desc, ... NS_REQUIRES_NIL_TERMINATION;
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:4];
    
    va_list arg_list;
    va_start(arg_list, desc);// 获取后续参数的偏移
    NSString *device = va_arg(arg_list, NSString *);
    NSMutableArray *lst = [NSMutableArray arrayWithCapacity:3];
    if(device){
        [lst addObject:[device copy]];
    }
    
    while(device){
        device = va_arg(arg_list, NSString *);
        [lst addObject:[device copy]];
    }
    va_end(arg_list);
    
    if(lst.count == 1){
        [result setObject:[lst firstObject] forKey:@"paraDict"];
    } else if(lst.count > 1){
        //
        NSInteger count = lst.count / 2;
        for (NSInteger i = 0; i < count; i++){
            [result setObject:[lst objectAtIndex:i * 2 + 1] forKey:[lst objectAtIndex:i * 2]];
        }
    }
    return result;
}
@end
