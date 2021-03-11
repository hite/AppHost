//
//  AHWebViewPreLoader.m
//  
//
//  Created by liang on 2019/7/16.
//  Copyright © 2019 Smily.Co. All rights reserved.
//

#import "AHWebViewPreLoader.h"
#import "AHSimpleWebViewController.h"


NSString * const kPreloadResourceConfCacheKey = @"kPreloadResourceConfCacheKey";

@implementation AHWebViewPreLoader {
    UIWindow *_no3;
}

+ (instancetype)defaultLoader {
    static AHWebViewPreLoader *kDefaultLoader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kDefaultLoader = [AHWebViewPreLoader new];
        
        UIWindow *win = [[UIWindow alloc] initWithFrame:CGRectMake(AH_SCREEN_WIDTH, 0, 10, 10)];
        
        win.windowLevel = UIWindowLevelStatusBar + 14;
        
        kDefaultLoader->_no3 = win;
    });
    
    return kDefaultLoader;
}

/**
 从服务器下载最新的配置到 ud 里
 */
- (void)updateConfig:(bFetchConfig)fetchConfig {
    if (fetchConfig) {
        NSDictionary *conf = fetchConfig(kAHPreloadResourceVersion);
        if ([conf isKindOfClass:NSDictionary.class]) {
            [[NSUserDefaults standardUserDefaults] setObject:conf forKey:kPreloadResourceConfCacheKey];
        }
        
    }
    AHLog("kPreloadResourceVersion = %d\n", kAHPreloadResourceVersion);
}

- (void)loadResources {
    // 使用上次获取的数据
    NSDictionary *conf = [[NSUserDefaults standardUserDefaults] objectForKey:kPreloadResourceConfCacheKey];

    if ([conf isKindOfClass:NSDictionary.class]) {
        [self renderWebView:conf];
    }
}

-(NSString*)jsonStringFromDictionary:(NSDictionary *)dic {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic
                                                       options:0
                                                         error:&error];
    
    if (!jsonData) {
        AHLog(@"%s: error: %@", __func__, error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

- (void)renderWebView:(NSDictionary *)model {
    // 获取模板字符串，准备替换 #{CONF}
    NSURL *resourceURL = [[NSBundle mainBundle] URLForResource:@"preload_resources" withExtension:@"html"];
    NSError *err = nil;
    NSString *tmpl = [NSString stringWithContentsOfURL:resourceURL encoding:NSUTF8StringEncoding error:&err];
    NSString *dataSource = [self jsonStringFromDictionary: model];
    
    AHSimpleWebViewController *vc = [AHSimpleWebViewController new];
    vc.domain = [model objectForKey:@"domain"];
    vc.htmlString = [tmpl stringByReplacingOccurrencesOfString:@"#{CONF}" withString:dataSource];;
    
    _no3.rootViewController = vc;
    _no3.hidden = NO;// 必须是显示的 window，才会触发预热 ViewController，隐藏的 window 不可用。但是和是否在屏幕可见没关系
}
    
@end
