//
//  AHPrefetchMonitor.h
//  AppHost
//
//  Created by hite on 2021/3/12.
//  Copyright © 2021 liang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
//int TYPE_MISS = 1; //当前接口未命中配置表
//int TYPE_PROCESSING = 2; //接口正在请求中
//int TYPE_FAILED = 3; //接口请求失败
//int TYPE_SUCCESS = 4; //接口请求成功, 可以从prefetchData中获取数据
//int TYPE_ERROR = 5;  //前端jsb传递的参数错误

typedef NS_ENUM(NSInteger, AHPrefetchStatus) {
    AHPrefetchStatusDefault = 0,
    AHPrefetchStatusUnHit = 1,
    AHPrefetchStatusInProcessing,
    AHPrefetchStatusFailed,
    AHPrefetchStatusSucc,
    AHPrefetchStatusError
};
@interface AHPrefetchMetrics : NSObject

@property (nonatomic, assign) int32_t hashKey;
@property (nonatomic, strong) NSString *url;

@property (nonatomic, strong) NSString *api;
@property (nonatomic, strong) NSString *method;
// 请求预加载的时间
@property (nonatomic, assign) NSInteger loadTime;

// 请求数据返回的时间，某个 api
@property (nonatomic, assign) NSInteger readyTime;
@property (nonatomic, assign) NSInteger loadFailTime;

// h5 请求数据的时间，
@property (nonatomic, assign) NSInteger fetchTime;

@end

@interface AHPrefetchMonitor : NSObject
+ (instancetype)sharedInstance;

- (void)markLoadTime:(NSInteger)realTime forHash:(int32_t)hash url:(NSString *)url api:(NSString *)api;

- (void)markReadyTime:(int32_t)hash;

- (void)markLoadFailTime:(int32_t)hash;

- (void)markFetchTime:(int32_t)hash;
@end


NS_ASSUME_NONNULL_END
