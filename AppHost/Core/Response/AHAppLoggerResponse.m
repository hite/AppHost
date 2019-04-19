//
//  MKAppLoggerResponse.m

//
//  Created by liang on 06/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import "AHAppLoggerResponse.h"

@implementation AHAppLoggerResponse

+ (NSDictionary<NSString *, NSString *> *)supportActionList
{
    return @{
             @"log_" : @"1"
             };
}

ah_doc_begin(log_, "在 xcode 控制台输出日志")
ah_doc_param(logData, "日志字段，通常是json 对象")
ah_doc_code(window.appHost.invoke("log",{"text":"Error"}))
ah_doc_code_expect("会在 xcode 控制台输出日志信息，输出 text: Error, 日志包含了 [AppHost] 前缀")
ah_doc_end
- (void)log:(NSDictionary *)logData
{
    AHLog(@"Logs from webview: %@", logData);
}

@end
