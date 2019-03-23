//
//  AppHostViewController+Scripts.m
//  AppHost
//
//  Created by liang on 2019/3/23.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AppHostViewController+Scripts.h"
#import "AppHostViewController+Utils.h"

@implementation AppHostViewController (Scripts)

- (void)insertData:(NSDictionary *)json intoPageWithVarName:(NSString *)appProperty
{
    NSData *objectOfJSON = nil;
    NSError *contentParseError = nil;
    
    objectOfJSON = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&contentParseError];
    if (contentParseError == nil && objectOfJSON) {
        NSString *str = [[NSString alloc] initWithData:objectOfJSON encoding:NSUTF8StringEncoding];
        [self executeJavaScriptString:[NSString stringWithFormat:@"if(window.appHost){window.appHost.%@ = %@;}", appProperty, str]];
    }
}


- (void)executeJavaScriptString:(NSString *)javaScriptString
{
    [self.webView evaluateJavaScript:javaScriptString completionHandler:nil];
}

#pragma mark - public

- (void)fireCallback:(NSString *)actionName param:(NSDictionary *)paramDict
{
    [self __execScript:actionName funcName:@"__callback" param:paramDict];
}

- (void)fireAction:(NSString *)actionName param:(NSDictionary *)paramDict
{
    [self __execScript:actionName funcName:@"__fire" param:paramDict];
}

- (void)__execScript:(NSString *)actionName funcName:(NSString *)funcName param:(NSDictionary *)paramDict
{
    NSData *objectOfJSON = nil;
    NSError *contentParseError;
    
    objectOfJSON = [NSJSONSerialization dataWithJSONObject:paramDict options:NSJSONWritingPrettyPrinted error:&contentParseError];
    
    NSString *jsCode = [NSString stringWithFormat:@"window.appHost.%@('%@',%@);", funcName, actionName, [[NSString alloc] initWithData:objectOfJSON encoding:NSUTF8StringEncoding]];
    [self logRequestAndResponse:jsCode type:@"response"];
    jsCode = [jsCode stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    [self executeJavaScriptString:jsCode];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAppHostInvokeResponseEvent
                                                        object:@{
                                                                 @"action": actionName,
                                                                 @"param": paramDict
                                                                 }];
}

- (void)injectScriptsToUserContent:(WKUserContentController *)userContentController
{
    // 注入关键 js 文件
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *jsLibURL = [[bundle bundleURL] URLByAppendingPathComponent:@"appHost_version_1.5.0.js"];
    
    NSString *jsLib = [NSString stringWithContentsOfURL:jsLibURL encoding:NSUTF8StringEncoding error:nil];
    if (jsLib.length > 0) {
        WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:jsLib injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript];
        WKUserScript *cookieScript1 = [[WKUserScript alloc] initWithSource:@"console.log('start = ' + (new Date()).getTime())" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript1];
        WKUserScript *cookieScript2 = [[WKUserScript alloc] initWithSource:@"console.log('end = ' + (new Date()).getTime())" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript2];
        // profile
        NSURL *profile = [[bundle bundleURL] URLByAppendingPathComponent:@"/profile/profiler.js"];
        NSString *profileTxt = [NSString stringWithContentsOfURL:profile encoding:NSUTF8StringEncoding error:nil];
        WKUserScript *cookieScript3 = [[WKUserScript alloc] initWithSource:profileTxt injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript3];
        
        NSURL *timing = [[bundle bundleURL] URLByAppendingPathComponent:@"/profile/pageTiming.js"];
        NSString *timingTxt = [NSString stringWithContentsOfURL:timing encoding:NSUTF8StringEncoding error:nil];
        WKUserScript *cookieScript4 = [[WKUserScript alloc] initWithSource:timingTxt injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript4];
    } else {
        NSAssert(NO, @"主 JS 文件加载失败");
        AHLog(@"Fatal Error: appHost.js is not loaded.");
    }
}

@end
