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
- (BOOL)handleAction:(NSString *)action withParam:(NSDictionary *)paramDict callbackKey:(NSString *)callbackKey
{
#ifdef DEBUG
    if ([@"eval" isEqualToString:action]) {
        [self.appHost.webView evaluateJavaScript:[paramDict objectForKey:@"code"] completionHandler:^(id _Nullable result, NSError * _Nullable error) {
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
        Class appHostCls = [[AHResponseManager defaultManager] responseForAction:action];
        SEL targetMethod = NSSelectorFromString([NSString stringWithFormat:@"%@%@", ah_doc_log_prefix, action]);
        if ([appHostCls respondsToSelector:targetMethod]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSDictionary *doc = [appHostCls performSelector:targetMethod withObject:nil];
#pragma clang diagnostic pop
            [self fire:[@"apropos." stringByAppendingString:action] param:doc];
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
        //
        [self.appHost fire:@"requestToTiming" param:@{}];
    }else {
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
    @"timing" : @"1"
#endif
  };
}

// 注入 weinre 文件
- (void)enableWeinreSupport
{
    if (kLastWeinreScript.length == 0) {
        return;
    }
    [self.appHost fire:@"weinre.enable" param:@{@"jsURL": kLastWeinreScript}];
}

- (void)disableWeinreSupport
{
    kLastWeinreScript = nil;
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
