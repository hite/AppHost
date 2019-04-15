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
#import "AppHostViewController+Scripts.h"

// 保存 weinre 注入脚本的地址，方便在加载其它页面时也能自动注入。
static NSString *kLastWeinreScript = nil;
@implementation AHDebugResponse

+ (void)setupDebugger
{
#ifdef AH_DEBUG
    NSBundle *bundle = [NSBundle bundleForClass:AppHostViewController.class];
    NSMutableArray *scripts = [NSMutableArray arrayWithObjects:
                         @{// 记录 window.DocumentEnd 的时间
                             @"code": @"window.DocumentEnd =(new Date()).getTime()",
                             @"when": @(WKUserScriptInjectionTimeAtDocumentEnd),
                             @"key": @"documentEndTime.js"
                             },
                         @{// 记录 DocumentStart 的时间
                             @"code": @"window.DocumentStart = (new Date()).getTime()",
                             @"when": @(WKUserScriptInjectionTimeAtDocumentStart),
                             @"key": @"documentStartTime.js"
                             },
                           @{// 重写 console.log 方法
                             @"code": @"window.__ah_consolelog = console.log; console.log = function(_msg){window.__ah_consolelog(_msg);appHost.invoke('console.log', {'text':_msg})}",
                             @"when": @(WKUserScriptInjectionTimeAtDocumentStart),
                             @"key": @"console.log.js"
                             },
                         @{// 记录 readystatechange 的时间
                             @"code": @"document.addEventListener('readystatechange', function (event) {window['readystate_' + document.readyState] = (new Date()).getTime();});",
                             @"when": @(WKUserScriptInjectionTimeAtDocumentStart),
                             @"key": @"readystatechange.js"
                             },nil
                         ];

    NSURL *profile = [[bundle bundleURL] URLByAppendingPathComponent:@"/profile/profiler.js"];
    NSString *profileTxt = [NSString stringWithContentsOfURL:profile encoding:NSUTF8StringEncoding error:nil];
    // profile
    [scripts addObject:@{
                         @"code": profileTxt,
                         @"when": @(WKUserScriptInjectionTimeAtDocumentEnd),
                         @"key": @"profile.js"
                         }];
    
    NSURL *timing = [[bundle bundleURL] URLByAppendingPathComponent:@"/profile/pageTiming.js"];
    NSString *timingTxt = [NSString stringWithContentsOfURL:timing encoding:NSUTF8StringEncoding error:nil];
    // timing
    [scripts addObject:@{
                         @"code": timingTxt,
                         @"when": @(WKUserScriptInjectionTimeAtDocumentEnd),
                         @"key": @"timing.js"
                         }];
    
    [scripts enumerateObjectsUsingBlock:^(NSDictionary  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [AppHostViewController prepareJavaScript:[obj objectForKey:@"code"] when:[[obj objectForKey:@"when"] integerValue] key:[obj objectForKey:@"key"]];
    }];
#endif
}

- (BOOL)handleAction:(NSString *)action withParam:(NSDictionary *)paramDict callbackKey:(NSString *)callbackKey
{
#ifdef DEBUG
    if ([@"eval" isEqualToString:action]) {
        [self.appHost evalExpression:[paramDict objectForKey:@"code"] completion:^(id  _Nonnull result, NSString * _Nonnull error) {
            AHLog(@"%@, error = %@", result, error);
            NSDictionary *r = nil;
            if (result) {
                r = @{
                      @"result":[NSString stringWithFormat:@"%@", result]
                      };
            } else {
                r = @{
                      @"error":[NSString stringWithFormat:@"%@", error]
                      };
            }
            [self fire:@"eval" param:r];
        }];
    } else if ([@"list" isEqualToString:action]) {
        // 遍历所有的可用接口和注释和测试用例
        //TODO 分页
        [self fire:@"list" param:[[AHResponseManager defaultManager] allResponseMethods]];
    } else if ([@"apropos" isEqualToString:action]) {
        NSString *name = [paramDict objectForKey:@"name"];
        Class appHostCls = [[AHResponseManager defaultManager] responseForAction:name];
        SEL targetMethod = NSSelectorFromString([NSString stringWithFormat:@"%@%@", ah_doc_log_prefix, name]);
        NSString *funcName = [@"apropos." stringByAppendingString:name];
        if ([appHostCls respondsToSelector:targetMethod]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSDictionary *doc = [appHostCls performSelector:targetMethod withObject:nil];
#pragma clang diagnostic pop
            
            [self fire:funcName param:doc];
        } else {
            [self fire:funcName param:@{@"error":[NSString stringWithFormat:@"method (%@) not found!",name]}];
        }
    }else if ([@"testcase" isEqualToString:action]) {
        // 检查是否有文件生成，如果没有则遍历
        NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *file = [docsdir stringByAppendingPathComponent:kAppHostTestCaseFileName];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:file]) {
            [self generatorHtml];
        }
        [self.appHost loadLocalFile:[NSURL fileURLWithPath:file] domain:@"http://you.163.com"];
        // 支持 或者关闭 weinre 远程调试
    }else if ([@"weinre" isEqualToString:action]) {
        //
        BOOL disabled = [[paramDict objectForKey:@"disabled"] boolValue];
        if (disabled) {
            [self disableWeinreSupport];
        } else {
            kLastWeinreScript = [paramDict objectForKey:@"url"];
            [self enableWeinreSupport];
        }
    }else if ([@"timing" isEqualToString:action]) {
        BOOL mobile = [[paramDict objectForKey:@"mobile"] boolValue];
        if (mobile) {
            [self.appHost fire:@"requestToTiming" param:@{}];
        } else {
            [self.appHost.webView evaluateJavaScript:@"window.performance.timing.toJSON()" completionHandler:^(NSDictionary *_Nullable r, NSError * _Nullable error) {
                [self fire:@"requestToTiming_on_mac" param:r];
            }];
        }
        //
    } else if ([@"console.log" isEqualToString:action]) {
        // 正常的日志输出时，不需要做特殊处理。
        // 因为在 invoke 的时候，已经向 debugger Server 发送过日志数据，已经打印过了
    } else {
        return NO;
    }
    return YES;
    
#else
    return NO;
#endif
}

+ (NSDictionary<NSString *, NSString *> *)supportActionList {
  return @{
#ifdef DEBUG
    @"eval" : @"1",
    @"list" : @"1",
    @"apropos": @"1",
    @"testcase" : @"1",
    @"weinre" : @"1",
    @"timing" : @"1",
    @"console.log": @"1"
#endif
  };
}

// 注入 weinre 文件
- (void)enableWeinreSupport
{
    if (kLastWeinreScript.length == 0) {
        return;
    }
    [AppHostViewController prepareJavaScript:[NSURL URLWithString:kLastWeinreScript] when:WKUserScriptInjectionTimeAtDocumentEnd key:@"weinre.js"];
    [self.appHost fire:@"weinre.enable" param:@{@"jsURL": kLastWeinreScript}];
}

- (void)disableWeinreSupport
{
    kLastWeinreScript = nil;
    [AppHostViewController removeJavaScriptForKey:@"weinre.js"];
}

#pragma mark - generate html file
/**
 <fieldset>
 <legend>杂项</legend>
 <ol>
 <li>
 <a href="http://www.163.com" onclick="toggleBounce();return false;">切换 页面的bounce的状态</a>
 <span>是否显示ios原生的bounce属性</span>
 </li>
 </ol>
 </fieldset>

 */
- (void)generatorHtml
{
//    {{ALL_DOCS}}
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *url = [bundle URLForResource:@"testcase" withExtension:@"tmpl"];
    // 获取模板
    NSError *err = nil;
    NSString *template = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
    if (template.length > 0 && err == nil) {
        // 解析
        AHLog(@"正在解析");
        NSArray *allClazz = [AHResponseManager defaultManager].customResponseClasses;
        NSMutableArray *docsHtml = [NSMutableArray arrayWithCapacity:4];
        for (Class clazz in allClazz) {
            NSDictionary* supportFunc = [clazz supportActionList];
            NSMutableString *html = [NSMutableString stringWithFormat:@"<fieldset><legend>%@</legend><ol>", NSStringFromClass(clazz)];
            for (NSString *func in supportFunc.allKeys) {
                NSInteger ver =  [[supportFunc objectForKey:func] integerValue];
                if (ver > 0) {
                    SEL targetMethod = NSSelectorFromString([NSString stringWithFormat:@"%@%@", ah_doc_log_prefix, func]);
                    if ([clazz respondsToSelector:targetMethod]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        NSDictionary *doc = [clazz performSelector:targetMethod withObject:nil];
#pragma clang diagnostic pop
                        if (doc) {
                            [html appendFormat:@"<li>\
                            <a href='http://www.163.com' onclick='%@;return false;'>%@</a>\
                            <span>%@</span>\
                             </li>", [doc objectForKey:@"code"], [doc objectForKey:@"discuss"], [doc objectForKey:@"codeResult"]];
                        }
                    }
                }
            }
            [html appendString:@"</ol></fieldset>"];
            [docsHtml addObject:html];
        }
        AHLog(@"解析完毕");
        if (docsHtml.count > 0) {
            template = [template stringByReplacingOccurrencesOfString:@"{{ALL_DOCS}}" withString:[docsHtml componentsJoinedByString:@""]];
        }
        
        NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *file = [docsdir stringByAppendingPathComponent:kAppHostTestCaseFileName];
        NSError *err = nil;
        [template writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:&err];
        if (err) {
            AHLog(@"解析文件有错误吗，%@", err);
        } else {
            AHLog(@"测试文件生成完毕，%@", file);
        }

    }

    
}
@end
