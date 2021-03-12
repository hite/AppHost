//
//  AHPrefetchResponse.m
//  AppHost
//
//  Created by hite on 2021/3/12.
//  Copyright © 2021 liang. All rights reserved.
//

#import "AHPrefetchResponse.h"

@implementation AHPrefetchResponse
+ (NSDictionary<NSString *, NSString *> *)supportActionList
{
    return @{
             @"fetchDataForHash_" : @"1"
             };
}

ah_doc_begin(fetchDataForHash_, "H5 请求获取对应 URL 和 api 的客户端缓存")
ah_doc_param(hash, "数字，是由代码样例中的函数生成的 hash 值 int32_t")
ah_doc_code(function strHashCode(str) {
    var hash = 0, i, chr;
    if (str.length === 0) return hash;
    for (i = 0; i < str.length; i++) {
      chr   = str.charCodeAt(i);
      hash  = ((hash << 5) - hash) + chr;
      hash |= 0; // Convert to 32bit integer
    }
    return hash;
  };)
ah_doc_code_expect("在回调里返回此 api 请求的缓存值，可能为空，由 status 字段标示")
ah_doc_end
- (void)fetchDataForHash:(int32_t *)hash
{
    static NSString *callbackKey = @"returnPrefetchData";
    int32_t hash = [dic[@"hashString"] intValue];
    NSDictionary *ret = [self.appHost.prefetchLoader cacheForHash:hash];
    if (ret) {
        [self.appHost fire:callbackKey param:@{
            @"status": @(AHPrefetchStatusSucc),
            @"prefetchData": ret
        }];
    } else {
        [self.appHost fire:callbackKey param:@{
            @"status": @(AHPrefetchStatusFailed)
        }];
    }
}

@end
