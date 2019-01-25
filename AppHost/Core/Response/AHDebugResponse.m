//
//  AHDebugResponse.m
//  AppHost
//
//  Created by liang on 2019/1/22.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AHDebugResponse.h"
#import "AHResponseManager.h"
#import "AppHostViewController.h"

@implementation AHDebugResponse
- (BOOL)handleAction:(NSString *)action withParam:(NSDictionary *)paramDict
{

#ifdef DEBUG
    if ([@"eval" isEqualToString:action]) {
        [self.appHost.webView evaluateJavaScript:[paramDict objectForKey:@"code"] completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            AHLog(@"%@", result);
        }];
    } else if ([@"api_list" isEqualToString:action]) {
        // 遍历所有的可用接口和注释和测试用例
        NSString *action = [paramDict objectForKey:@"name"];
        if (action.length == 0) {
            [self callbackFunctionOnWebPage:@"api_list" param:[[AHResponseManager defaultManager] allResponseMethods]];
        } else {// 如果是具体的某个接口，输出对应的 API 描述
            id<AppHostProtocol> appHost = [[AHResponseManager defaultManager] responseForAction:action withAppHost:nil];
            SEL targetMethod = NSSelectorFromString([NSString stringWithFormat:@"%@%@", ah_doc_log_prefix, action]);
            if ([appHost respondsToSelector:targetMethod]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                NSDictionary *doc = [appHost performSelector:targetMethod withObject:nil];
#pragma clang diagnostic pop
                [self callbackFunctionOnWebPage:[@"api_list." stringByAppendingString:action] param:doc];
            }
        }
    } else if ([@"testcase" isEqualToString:action]) {
        // 检查是否有文件生成，如果没有则遍历
    } else {
        return NO;
    }
    return YES;
    
#else
    return NO;
#endif
}

+ (NSDictionary<NSString *, NSString *> *)supportActionList
{
    return @{
#ifdef DEBUG
             @"eval" : @"1",
             @"api_list" : @"1"
#endif
             };
}

@end
