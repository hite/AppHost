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
    [self.webView evaluateJavaScript:[NSString stringWithFormat:@"window.ah_eval(%@)", jsCode] completionHandler:^(NSDictionary *data, NSError * _Nullable error) {
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
    jsCode = [jsCode stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    [self executeJavaScriptString:jsCode];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAppHostInvokeResponseEvent
                                                        object:@{
                                                                 kAHActionKey: actionName,
                                                                 kAHParamKey: paramDict
                                                                 }];
}


+ (void)prepareJavaScript:(id)script when:(WKUserScriptInjectionTime)injectTime key:(NSString *)key
{
    if ([script isKindOfClass:NSString.class]) {
        [self _addJavaScript:script when:injectTime forKey:key];
    } else if ([script isKindOfClass:NSURL.class]){
        NSString * result = NULL;
        NSURL * urlToRequest = (NSURL*)script;
        if(urlToRequest){
            // 这里使用异步下载的方式，也可以使用 stringWithContentOfURL 的方法，同步获取字符串
            // 注意1：http 的资源不会被 https 的网站加载 // upgrade-insecure-requests
            // 注意2：stringWithContentOfURL 获取的 weinre文件，需要设置 ServerURL blabla 的东西
            result = [NSString stringWithFormat:ah_ml((function(e){
                e.setAttribute("src",'%@');
                document.getElementsByTagName('body')[0].appendChild(e);
            })(document.createElement('script'));), urlToRequest.absoluteString];
            [self _addJavaScript:result when:injectTime forKey:key];
        }
    } else {
        AHLog(@"fail to inject javascript");
    }
}

static NSMutableArray *kAppHostCustomJavscripts = nil;
+ (void)_addJavaScript:(NSString *)script when:(WKUserScriptInjectionTime)injectTime forKey:(NSString *)key
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kAppHostCustomJavscripts = [NSMutableArray arrayWithCapacity:4];
    });
    
    @synchronized (kAppHostCustomJavscripts) {
        [kAppHostCustomJavscripts addObject:@{
                                              @"script": script,
                                              @"when": @(injectTime),
                                              @"key":key
                                              }];
    }
}

+ (void)removeJavaScriptForKey:(NSString *)key
{
    @synchronized (kAppHostCustomJavscripts) {
        [kAppHostCustomJavscripts enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj objectForKey:key]) {
                [kAppHostCustomJavscripts removeObject:obj];
                *stop = YES;
            }
        }];
    }
}

static NSString *kAppHostSource = nil;
- (void)injectScriptsToUserContent:(WKUserContentController *)userContentController
{
    NSBundle *bundle = [NSBundle bundleForClass:AppHostViewController.class];
    // 注入关键 js 文件, 有缓存
    if (kAppHostSource == nil) {
        NSURL *jsLibURL = [[bundle bundleURL] URLByAppendingPathComponent:@"appHost_version_1.5.0.js"];
        kAppHostSource = [NSString stringWithContentsOfURL:jsLibURL encoding:NSUTF8StringEncoding error:nil];
        [self.class _addJavaScript:kAppHostSource when:WKUserScriptInjectionTimeAtDocumentStart forKey:@"appHost.js"];
        
        // 注入脚本，用来代替 self.webView evaluateJavaScript:javaScriptString completionHandler:nil
        // 因为 evaluateJavaScript 的返回值不支持那么多的序列化结构的数据结构，还有内存泄漏的问题
        jsLibURL = [[bundle bundleURL] URLByAppendingPathComponent:@"eval.js"];
        NSString *evalJS = [NSString stringWithContentsOfURL:jsLibURL encoding:NSUTF8StringEncoding error:nil];
        [self.class _addJavaScript:evalJS when:WKUserScriptInjectionTimeAtDocumentEnd forKey:@"eval.js"];
    }
    [kAppHostCustomJavscripts enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:[obj objectForKey:@"script"] injectionTime:[[obj objectForKey:@"when"] integerValue] forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript];
    }];
}

@end
