//
//  AHPrefechLoader.m
//  AppHost
//
//  Created by hite on 2021/3/12.
//  Copyright © 2021 liang. All rights reserved.
//

#import "AHPrefechLoader.h"
#import "AHPrefetchMonitor.h"

@implementation AHPrefetchfigInterfacesModel

@end

@implementation AHPrefetchfigItemModel

@end


@implementation AHPrefechLoader{
    NSArray<AHPrefetchfigItemModel *> *_configs;
    NSCache *_responseCache;
    dispatch_queue_t _queue;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static AHPrefechLoader *instance;
    dispatch_once(&once, ^{
        instance = [self new];
        instance->_responseCache = [[NSCache alloc] init];
        instance->_queue = dispatch_queue_create("me.hite.webview.prefetch", DISPATCH_QUEUE_CONCURRENT);
        
        [instance loadConfigFile];
    });
    return instance;
}

- (void)loadConfigFile{

    NSString *jsonUrl = @"<real api>";

    NSURL *URL = [NSURL URLWithString:jsonUrl];

    [[[NSURLSession sharedSession] dataTaskWithURL:URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable err) {
        NSString *errorType = nil;
        if (data && !err) {
            NSError *error;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if (!error) {
                NSArray *config = [[json objectForKey:@"data"] objectForKey:@"config"];
                if ([config isKindOfClass:NSArray.class]) {
                    if (config.count > 10) {
                        config = [config subarrayWithRange:NSMakeRange(0, 10)];
                    }

                    NSMutableArray *lst = [NSMutableArray arrayWithCapacity:10];
                    [config enumerateObjectsUsingBlock:^(NSDictionary  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        AHPrefetchfigItemModel *model = [AHPrefetchfigItemModel new];
                        // obj 转 model
                        if (model) {
                            [lst addObject:model];
                        }
                    }];
                    
                    dispatch_barrier_async(self->_queue, ^{
                        self->_configs = [lst copy];
                    });
                }
            } else {
                NSLog(@"[WebViewConfig] 解析出错，error = %@", error);
                errorType = @"parseError";
            }
        } else {
            NSLog(@"[WebViewConfig] download 出错, error = %@", err);
            errorType = @"loadError";
        }
        // 发送统计数据
        if (errorType) {
            //
        }
        
        }] resume];
}

- (AHPrefetchfigItemModel *)configForUrl:(NSString *)url{
    __block AHPrefetchfigItemModel * config = nil;
    NSURL *targetURL = [NSURL URLWithString:url];
    if (!targetURL) {
        return nil;
    }
    dispatch_sync(_queue, ^{
        [self->_configs enumerateObjectsUsingBlock:^(AHPrefetchfigItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSURL *URL = [NSURL URLWithString:obj.url];
            if ([targetURL.host isEqualToString:URL.host] && [targetURL.path isEqualToString:URL.path]) {
                config = obj;
                *stop = YES;
            }
        }];
    });
    return config;
}

- (void)preFetchInterfaces:(NSArray<AHPrefetchfigInterfacesModel *> *)interfaces loadTime:(NSInteger)realLoadTime forUrl:(NSString *)url{
#ifdef DEBUG
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
#else
    NSURLSession *session = [NSURLSession sharedSession];
#endif
    
    for (NSInteger i = 0; i < interfaces.count; i++) {
        AHPrefetchfigInterfacesModel *item = interfaces[i];

        if (item.api.length == 0) {
            break;
        }
        
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:item.api] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:50];
        // 把 login cookie 里的带上
        NSString *cookie = @"";
        [req setValue:cookie forHTTPHeaderField:@"Cookie"];
        
        req.HTTPMethod = item.method;
        
        int32_t key = [self hash:item];
        [[AHPrefetchMonitor sharedInstance] markLoadTime:realLoadTime forHash:key url:url api:item.api];
        [[session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (error) {
                [[AHPrefetchMonitor sharedInstance] markLoadFailTime:key];
            }
            if (!data) {
                return  ;
            }

            NSString *responseData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if(responseData == nil){
                return  ;
            }
            // 如果 h5 已经获取过了，可以不保存
            [self->_responseCache setObject:responseData forKey:@(key)];
            [[AHPrefetchMonitor sharedInstance] markReadyTime:key];
            
        }] resume];
    }
}

- (int32_t)hash:(AHPrefetchfigInterfacesModel *)item{

    NSString *str = [NSString stringWithFormat:@"%@^%@", item.api, item.method];
    int32_t hash = 0, i = 0, chr = 0;
    if (str.length == 0) {
        return 0;
    }
    for (i = 0; i < str.length; i++) {
        unichar word = [str characterAtIndex:i];
        chr = [[NSNumber numberWithUnsignedChar:word] intValue];
        hash = ((hash << 5) - hash) + chr;
        hash |= 0;// Convert to 32bit integer
    }
    
    return hash;
}

#pragma mark -  public
-  (NSString *)getCSRFTokenFromCookie{
    NSArray<NSHTTPCookie *> *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
    __block NSString *csrfToken = nil;
    [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:@"yx_csrf"]) {
            csrfToken = obj.value;
            *stop = YES;
        }
    }];
    return csrfToken;
}

#ifdef DEBUG
// 这里回调是为了解决在测试环境下 SSL 证书报错存在的；
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    if (challenge.protectionSpace != Nil) {
        NSURLProtectionSpace *protection = challenge.protectionSpace;

        SecTrustRef sslState = protection.serverTrust;
        if (sslState == Nil) {
            NSLog(@"%s Warning: empty serverTrust",__PRETTY_FUNCTION__);
        }


        if ([protection.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {

            NSLog(@"%s => NSURLAuthenticationMethodServerTrust", __PRETTY_FUNCTION__);
            // warning normaly I should check the validity of the SecTrustRef before to trust
            NSURLCredential* credential = [NSURLCredential credentialForTrust:sslState];

            // Put in command for test

           completionHandler(NSURLSessionAuthChallengeUseCredential, credential);

        } else {
            NSLog(@"%s => Called for another challenge", __PRETTY_FUNCTION__);
           completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, NULL);
        }

    }
}

#endif

- (void)prepareDataForUrl:(NSString *)url{
    AHPrefetchfigItemModel *config = [self configForUrl:url];
    if (config == nil) {
        return;
    }
    NSInteger realStartTime = [[NSDate date] timeIntervalSince1970] * 1000;
    [self preFetchInterfaces:config.interfaces loadTime:realStartTime forUrl:url];
}

- (NSDictionary *)cacheForHash:(int32_t)hash{
    NSDictionary *copied = [self->_responseCache objectForKey:@(hash)];
    [[AHPrefetchMonitor sharedInstance] markFetchTime:hash];
    return copied;
}

- (void)clearCacheDataForUrl:(NSString *)url{
    AHPrefetchfigItemModel *config = [self configForUrl:url];
    if (config) {
        for (NSInteger i = 0; i < config.interfaces.count; i++) {
            AHPrefetchfigInterfacesModel *item = config.interfaces[i];

            int32_t key = [self hash:item];
            [self->_responseCache removeObjectForKey:@(key)];
        }
    }
}


@end
