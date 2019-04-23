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
#ifdef AH_DEBUG
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
        NSString *signature = [paramDict objectForKey:@"signature"];
        Class appHostCls = [[AHResponseManager defaultManager] responseForActionSignature:signature];
        SEL targetMethod = ah_doc_selector(signature);
        NSString *funcName = [@"apropos." stringByAppendingString:signature];
        if (appHostCls && [appHostCls respondsToSelector:targetMethod]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSDictionary *doc = [appHostCls performSelector:targetMethod withObject:nil];
#pragma clang diagnostic pop
            
            [self fire:funcName param:doc];
        } else {
            NSString *err = nil;
            if (appHostCls) {
                err = [NSString stringWithFormat:@"The doc of method (%@) is not found!", signature];
            } else {
                err = [NSString stringWithFormat:@"The method (%@) doesn't exsit!", signature];
            }
            [self fire:funcName param:@{@"error":err}];
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
        // $ weinre --boundHost 10.242.24.59 --httpPort 9090
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
    } else if ([@"clearCookie" isEqualToString:action]) {
        // 清理 WKWebview 的 Cookie，和 NSHTTPCookieStorage 是独立的
        WKHTTPCookieStore * _Nonnull cookieStorage = [WKWebsiteDataStore defaultDataStore].httpCookieStore;
        [cookieStorage getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
            [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull cookie, NSUInteger idx, BOOL * _Nonnull stop) {
                [cookieStorage deleteCookie:cookie completionHandler:nil];
            }];
            
            [self.appHost fire:@"clearCookieDone" param:@{@"count":@(cookies.count)}];
        }];
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
#ifdef AH_DEBUG
    @"eval_" : @"1",
    @"list" : @"1",
    @"apropos_": @"1",
    @"testcase" : @"1",
    @"weinre_" : @"1",
    @"timing_" : @"1",
    @"console.log_": @"1",
    @"clearCookie": @"1"
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
 <li id="funcRow_f_1">
 <script type="text/javascript">
 function f_1(){
 var eleId = 'funcRow_f_1'
 NEJsbridge.call('LocalStorage.setItem', '{"key":"BIA_LS_act_bosslike_num","value":"123"}');
 window.report(true, 'funcRow_f_1')
 }
 </script>
 <a href="javascript:void(0);" onclick="f_1();return false;">LocalStorage.setItem, 将 BIA_LS_act_bosslike_num 的值保存为 123</a>
 <span>无</span><label class="passed">✅</label><label class="failed">❌</label>
 </li>
 </ol>
 </fieldset>

 */
- (void)generatorHtml
{

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *url = [bundle URLForResource:@"testcase" withExtension:@"tmpl"];
    // 获取模板
    NSError *err = nil;
    NSString *template = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
    if (template.length > 0 && err == nil) {
        // 解析
        AHLog(@"正在解析");
        int funcAutoTestBaseIdx = 0;
        int funcNonAutoTestBaseIdx = 0; // 不支持自动化测试的函数
        NSArray *allClazz = [AHResponseManager defaultManager].customResponseClasses;
        NSMutableArray *docsHtml = [NSMutableArray arrayWithCapacity:4];
        for (Class clazz in allClazz) {
            NSDictionary* supportFunc = [clazz supportActionList];
            NSMutableString *html = [NSMutableString stringWithFormat:@"<fieldset><legend>%@</legend><ol>", NSStringFromClass(clazz)];
      
            for (NSString *func in supportFunc.allKeys) {
                NSInteger ver =  [[supportFunc objectForKey:func] integerValue];
                if (ver > 0) {
                    SEL targetMethod = ah_doc_selector(func);
                    if ([clazz respondsToSelector:targetMethod]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        NSDictionary *doc = [clazz performSelector:targetMethod withObject:nil];
#pragma clang diagnostic pop
                        if (doc) {
                            // 这段代码来自 ruby 工程；
                            // js 函数的前缀，f_ 开通的为自动化测试函数， nf_ 开通的为手动验证函数
                            NSString *funcName = @"f_";
                            NSString *descPrefix = @"";
                            int funcBaseIdx = 0;
                            BOOL autoTest = [doc objectForKey:@"autoTest"];
                            if (autoTest) {
                                descPrefix = @"<label class=\"f-manual\">[手动]</label>";
                                funcName = @"nf_";
                                funcNonAutoTestBaseIdx += 1;
                                funcBaseIdx = funcNonAutoTestBaseIdx;
                            } else {
                                funcAutoTestBaseIdx += 1;
                                funcBaseIdx = funcAutoTestBaseIdx;
                            }
                            NSString *fullFunctionName = [funcName stringByAppendingFormat:@"%ld", (long)funcBaseIdx];
                            NSString *itemEleId = [@"funcRow_" stringByAppendingString:fullFunctionName];
                            
                            NSString *alertOrNot = @"";
                            if (![doc objectForKey:@"expectFunc"]) {// 如果没有 expectFunc 默认成功
                                alertOrNot = [NSString stringWithFormat:@"window.report(true, '%@')", itemEleId];
                            }
                            // 缺少插值运算的字符串拼接，让人头大
                            [html appendFormat:@"<li id=\"%@\">\
                             <script type=\"text/javascript\">\
                             function %@(){\
                                var eleId = '%@';%@; %@;\
                             }\
                             </script>\
                             <a href=\"javascript:void(0);\" onclick=\"%@();return false;\">%@%@, 执行后，%@</a>\
                             <span>%@</span><label class=\"passed\">✅</label><label class=\"failed\">❌</label>\
                             </li>",itemEleId, fullFunctionName, itemEleId,[doc objectForKey:@"code"],alertOrNot, fullFunctionName, descPrefix, [doc objectForKey:@"name"], [doc objectForKey:@"expect"], [doc objectForKey:@"discuss"]];
                        }
                    }
                } else {
                    AHLog(@"The '%@' not activiated", func);
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
