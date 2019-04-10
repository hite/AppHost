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

- (void)evalExpression:(NSString *)jsCode completion:(void (^)(id result, NSString *err))completion
{
    [self.webView evaluateJavaScript:[NSString stringWithFormat:@"window.ah_eval('%@')", jsCode] completionHandler:^(NSDictionary *data, NSError * _Nullable error) {
        if (completion) {
            completion([data objectForKey:@"result"], [data objectForKey:@"err"]);
        } else {
            NSLog(@"evalExpression result = %@", data);
        }
    }];
}

#pragma mark - public

- (void)fireCallback:(NSString *)callbackKey param:(NSDictionary *)paramDict
{
    [self __execScript:callbackKey funcName:@"__callback" param:paramDict];
}

- (void)fire:(NSString *)actionName param:(NSDictionary *)paramDict
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

static NSString *kAppHostSource = nil;
- (void)injectScriptsToUserContent:(WKUserContentController *)userContentController
{
    NSBundle *bundle = [NSBundle bundleForClass:AppHostViewController.class];
    // 注入关键 js 文件, 有缓存
    if (kAppHostSource == nil) {
        NSURL *jsLibURL = [[bundle bundleURL] URLByAppendingPathComponent:@"appHost_version_1.5.0.js"];
        kAppHostSource = [NSString stringWithContentsOfURL:jsLibURL encoding:NSUTF8StringEncoding error:nil];
    }
    
    if (kAppHostSource.length > 0) {
        WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:kAppHostSource injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript];
        
#ifdef AH_DEBUG
        // 记录 window.DocumentEnd 的时间
        WKUserScript *cookieScript1 = [[WKUserScript alloc] initWithSource:@"window.DocumentEnd =(new Date()).getTime()" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript1];
        // 记录 DocumentStart 的时间
        WKUserScript *cookieScript2 = [[WKUserScript alloc] initWithSource:@"window.DocumentStart = (new Date()).getTime()" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript2];
        // 记录 readystatechange 的时间
        WKUserScript *cookieScript2_1 = [[WKUserScript alloc] initWithSource:@"document.addEventListener('readystatechange', function (event) {window['readystate_' + document.readyState] = (new Date()).getTime();});" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript2_1];

        // profile
        NSURL *profile = [[bundle bundleURL] URLByAppendingPathComponent:@"/profile/profiler.js"];
        NSString *profileTxt = [NSString stringWithContentsOfURL:profile encoding:NSUTF8StringEncoding error:nil];
        WKUserScript *cookieScript3 = [[WKUserScript alloc] initWithSource:profileTxt injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript3];
        
        NSURL *timing = [[bundle bundleURL] URLByAppendingPathComponent:@"/profile/pageTiming.js"];
        NSString *timingTxt = [NSString stringWithContentsOfURL:timing encoding:NSUTF8StringEncoding error:nil];
        WKUserScript *cookieScript4 = [[WKUserScript alloc] initWithSource:timingTxt injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript4];
        
        // 注入脚本，用来代替 self.webView evaluateJavaScript:javaScriptString completionHandler:nil
        // 因为 evaluateJavaScript 的返回值不支持那么多的序列化结构的数据结构，还有内存泄漏的问题
        NSURL *jsLibURL = [[bundle bundleURL] URLByAppendingPathComponent:@"eval.js"];
        NSString *evalJS = [NSString stringWithContentsOfURL:jsLibURL encoding:NSUTF8StringEncoding error:nil];
        WKUserScript *cookieScript5 = [[WKUserScript alloc] initWithSource:evalJS injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript5];
#endif
    } else {
        NSAssert(NO, @"主 JS 文件加载失败");
        AHLog(@"Fatal Error: appHost.js is not loaded.");
    }
}

@end
