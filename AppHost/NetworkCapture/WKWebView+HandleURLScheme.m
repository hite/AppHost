//
//  WKWebView+HandleURLScheme.m
//  AppHost
//
//  Created by hite on 2021/3/11.
//  Copyright © 2021 liang. All rights reserved.
//

#import "WKWebView+HandleURLScheme.h"

@implementation WKWebView (HandleURLScheme)

+ (BOOL)handlesURLScheme:(NSString *)urlScheme{
    NSLog(@"Scheme Check for url = %@", urlScheme);
    return NO;
}

@end
