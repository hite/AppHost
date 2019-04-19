//
//  AppHostViewController+Dispatch.m
//  AppHost
//
//  Created by liang on 2019/3/23.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AppHostViewController+Dispatch.h"
#import "AppHostViewController+Scripts.h"
#import "AppHostViewController+Utils.h"
#import "AHResponseManager.h"

@implementation AppHostViewController (Dispatch)

#pragma mark - core
- (void)dispatchParsingParameter:(NSDictionary *)contentJSON
{
    // 增加对异常参数的catch
    @try {
        NSDictionary *paramDict = [contentJSON objectForKey:kAHParamKey];
        NSString *callbackKey = [contentJSON objectForKey:@"callbackKey"];
        [self callNative:[contentJSON objectForKey:kAHActionKey] parameter:paramDict callbackKey:callbackKey];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kAppHostInvokeRequestEvent object:contentJSON];
    } @catch (NSException *exception) {
        [self showTextTip:@"H5接口异常"];
        AHLog(@"h5接口解析异常，接口数据：%@", contentJSON);
    } @finally {
    }
}

#pragma mark - public
// 延迟初始化； 短路判断
- (BOOL)callNative:(NSString *)action parameter:(NSDictionary *)paramDict
{
    return [self callNative:action parameter:paramDict callbackKey:nil];
}

#pragma mark - private
- (BOOL)callNative:(NSString *)action parameter:(NSDictionary *)paramDict callbackKey:(NSString *)key
{
    AHResponseManager *rm = [AHResponseManager defaultManager];
    NSString *actionSig = [rm actionSignature:action withParam:paramDict withCallback:key.length > 0];
    id<AppHostProtocol> response = [rm responseForActionSignature:actionSig withAppHost:self];
    //
    if (response == nil || ![response handleAction:action withParam:paramDict callbackKey:key]) {
        NSString *errMsg = [NSString stringWithFormat:@"action (%@) not supported yet.", action];
        AHLog(@"action (%@) not supported yet.", action);
        [self fire:@"NotSupported" param:@{
                                           @"error": errMsg
                                           }];
        return NO;
    } else {
        return YES;
    }
}

@end
