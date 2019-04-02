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
        [self fire:@"NotSupported" param:@{
                                                           @"error": errMsg
                                                           }];
        return NO;
    } else {
        [vc handleAction:action withParam:paramDict];
        return YES;
    }
}

@end
