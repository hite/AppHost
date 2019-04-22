//
//  AHResponseManager.m
//  AppHost
//
//  Created by liang on 2019/1/22.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AHResponseManager.h"
#import<pthread.h>
#import "AHDebugResponse.h"

@interface AHResponseManager ()

// 以下是注册 response 使用的属性

/**
 自定义response类
 */
@property (nonatomic, strong, readwrite) NSMutableArray *customResponseClasses;
/**
 response类的 实例的缓存。
 */
@property (nonatomic, strong) NSMutableDictionary *responseClassObjs;

@end

@implementation AHResponseManager

+(instancetype)defaultManager
{
    static dispatch_once_t onceToken;
    static AHResponseManager *kResponeManger = nil;
    dispatch_once(&onceToken, ^{
        kResponeManger = [AHResponseManager new];
        
        kResponeManger.responseClassObjs = [NSMutableDictionary dictionaryWithCapacity:10];
        kResponeManger.customResponseClasses = [NSMutableArray arrayWithCapacity:10];
        
        // 静态注册 可响应的类
        NSArray<NSString *> *responseClassNames = @[
                                                    @"AHNavigationResponse",
                                                    @"AHNavigationBarResponse",
                                                    @"AHBuiltInResponse",
#ifdef AH_DEBUG
                                                    @"AHDebugResponse",
#endif
                                                    @"AHAppLoggerResponse"];
        [responseClassNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [kResponeManger.customResponseClasses addObject:NSClassFromString(obj)];
        }];
        
        //TODO
#ifdef AH_DEBUG
        NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *file = [docsdir stringByAppendingPathComponent:kAppHostTestCaseFileName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
            NSError *err = nil;
            [[NSFileManager defaultManager] removeItemAtPath:file error:&err];
            if (err) {
                AHLog(@"删除文件错误");
            }
        }
#endif
    });
    
    return kResponeManger;
}

#pragma mark - public
- (NSString *)actionSignature:(NSString *)action withParam:(BOOL)hasParamDict withCallback:(BOOL)hasCallback
{
    return [NSString stringWithFormat:@"%@%@%@", action, (hasParamDict?@"_":@""), (hasCallback?@"$":@"")];
}

- (void)addCustomResponse:(Class<AppHostProtocol>)cls
{
    if (cls) {
        [self.customResponseClasses addObject:cls];
    }
}

- (id<AppHostProtocol>)responseForActionSignature:(NSString *)signature withAppHost:(AppHostViewController * _Nonnull)appHost
{
    if (self.customResponseClasses.count == 0) {
        return nil;
    }
    
    id<AppHostProtocol> vc = nil;
    // 逆序遍历，让后添加的 Response 能够覆盖内置的方法；
    for (NSInteger i = self.customResponseClasses.count - 1; i >= 0; i--) {
        Class responseClass = [self.customResponseClasses objectAtIndex:i];
        if ([responseClass isSupportedActionSignature:signature]) {
            // 先判断是否可以响应，再决定初始化。
            if (appHost) {
                NSString *key = NSStringFromClass(responseClass);
                if (vc == nil) {
                    vc = [self.responseClassObjs objectForKey:key];
                    vc = [[responseClass alloc] initWithAppHost:appHost];
                    // 缓存住
                    [self.responseClassObjs setObject:vc forKey:key];
                }
            }  else {
                vc = [responseClass new];
            }
            
            break;
        }
    }
    
    return vc;
}

- (Class)responseForActionSignature:(NSString *)action
{
    // 逆序遍历，让后添加的 Response 能够覆盖内置的方法；
    Class r = nil;
    for (NSInteger i = self.customResponseClasses.count - 1; i >= 0; i--) {
        Class responseClass = [self.customResponseClasses objectAtIndex:i];
        if ([responseClass isSupportedActionSignature:action]) {
            r = responseClass;
            break;
        }
    }
    
    return r;
}

#ifdef AH_DEBUG

/**
 //TODO: 缓存
 */
static NSDictionary *kAllResponseMethods = nil;
static pthread_mutex_t lock;
- (NSDictionary *)allResponseMethods
{
    pthread_mutex_init(&lock, NULL);
    pthread_mutex_lock(&lock);
    if (kAllResponseMethods) {
        pthread_mutex_unlock(&lock);
        return kAllResponseMethods;
    }
    
    kAllResponseMethods = [NSMutableDictionary dictionaryWithCapacity:10];
    //
    for (NSInteger i = 0; i < self.customResponseClasses.count; i++) {
        Class responseClass = [self.customResponseClasses objectAtIndex:i];
        NSMutableArray *methods = [NSMutableArray arrayWithCapacity:10];
        [[responseClass supportActionList] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj integerValue] > 0) {
                [methods addObject:key];
            }
        }];
        
        if (methods.count > 0) {
            [kAllResponseMethods setValue:methods forKey:NSStringFromClass(responseClass)];
        }
    }
    
    pthread_mutex_unlock(&lock);
    return kAllResponseMethods;
}

#endif

-(void)dealloc
{
    // 清理 response
    [self.responseClassObjs enumerateKeysAndObjectsUsingBlock:^(NSString *key, id _Nonnull obj, BOOL *_Nonnull stop) {
        obj = nil;
    }];
    [self.responseClassObjs removeAllObjects];
    self.responseClassObjs = nil;
    
}
@end
