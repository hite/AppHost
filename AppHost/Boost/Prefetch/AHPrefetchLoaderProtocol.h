//
//  AHPrefetchLoaderProtocal.h
//  AppHost
//
//  Created by hite on 2021/3/12.
//  Copyright © 2021 liang. All rights reserved.
//


#import <Foundation/Foundation.h>

@protocol AHPrefetchLoaderProtocol <NSObject>

+ (instancetype)sharedInstance;

- (void)prepareDataForUrl:(NSString *)url;

- (void)clearCacheDataForUrl:(NSString *)url;

- (NSDictionary *)cacheForHash:(int32_t)hash;

@end
