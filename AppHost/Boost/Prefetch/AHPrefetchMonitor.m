//
//  AHPrefetchMonitor.m
//  AppHost
//
//  Created by hite on 2021/3/12.
//  Copyright © 2021 liang. All rights reserved.
//

#import "AHPrefetchMonitor.h"

@implementation AHPrefetchMetrics
    
@end

@implementation AHPrefetchMonitor{
//    线程安全
    NSCache *_metricsCache;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static AHPrefetchMonitor *instance;
    dispatch_once(&once, ^{
        instance = [self new];
        instance->_metricsCache = [[NSCache alloc] init];
    });
    return instance;
}

- (void)markLoadTime:(NSInteger)realTime forHash:(int32_t)hash url:(NSString *)url api:(NSString *)api{
    NSNumber *key = @(hash);
    [self->_metricsCache removeObjectForKey:key];
    
    AHPrefetchMetrics *metric = [AHPrefetchMetrics new];
    metric.hashKey = hash;
    metric.url = url;
    metric.api = api;
    if (realTime > 0) {
        metric.loadTime = realTime;
    } else {
        metric.loadTime = [[NSDate date] timeIntervalSince1970] * 1000;
    }
    
    [self->_metricsCache setObject:metric forKey:key];
}

- (void)markReadyTime:(int32_t)hash{
    AHPrefetchMetrics *metric = [self->_metricsCache objectForKey:@(hash)];
    if (metric) {
        metric.readyTime = [[NSDate date] timeIntervalSince1970] * 1000;
    }
}

- (void)markLoadFailTime:(int32_t)hash{
    AHPrefetchMetrics *metric = [self->_metricsCache objectForKey:@(hash)];
    if (metric) {
        metric.readyTime = [[NSDate date] timeIntervalSince1970] * 1000;
    }
}

- (AHPrefetchMetrics *)metricForHash:(int32_t)hash{
    return [self->_metricsCache objectForKey:@(hash)];;
}

- (void)markFetchTime:(int32_t)hash{
    AHPrefetchMetrics *metric = [self->_metricsCache objectForKey:@(hash)];
    AHPrefetchStatus status =  AHPrefetchStatusDefault;
    if (metric) {
        metric.fetchTime = [[NSDate date] timeIntervalSince1970] * 1000;
        
        if (metric.loadFailTime > 0){
            status = AHPrefetchStatusFailed;
        } else if (metric.readyTime > 0){
            status = AHPrefetchStatusSucc;
        } else if (metric.readyTime == 0){
            status = AHPrefetchStatusInProcessing;
        }
    } else {
        status = AHPrefetchStatusUnHit;
    }
    // 发送统计埋点
//    [[CSManager sharedManager] collectMetricDataWithName:@"h5_prefetch_status"
//                                                          tags:@{
//                                                              @"status":[NSString stringWithFormat:@"status_%@", @(status)],
//                                                          } fields:@{
//                                                              @"url": metric.url?:@"",
//                                                              @"api": metric.api?:@"",
//                                                              @"hashFromH5": @(hash), //  用来排查错误
//                                                              @"loadCostTime": @(metric.readyTime - metric.loadTime),
//                                                              @"ready2fetchTime": @(metric.fetchTime - metric.readyTime)
//                                                          }];
    [self->_metricsCache removeObjectForKey:@(hash)];
}

@end
