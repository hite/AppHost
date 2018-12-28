//
//  MKAppLoggerResponse.m

//
//  Created by liang on 06/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import "AHAppLoggerResponse.h"

@implementation AHAppLoggerResponse

- (BOOL)handleAction:(NSString *)action withParam:(NSDictionary *)paramDict
{
    if ([@"log" isEqualToString:action]) {
        [self log:paramDict];
    }
    
    return YES;
}

+ (NSDictionary<NSString *, NSString *> *)supportActionList
{
    return @{
             @"log" : @"1"
             };
}

- (void)log:(NSDictionary *)logData
{
    AHLog(@"Logs from webview: %@", logData);
}


@end
