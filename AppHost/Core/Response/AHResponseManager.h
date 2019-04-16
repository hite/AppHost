//
//  AHResponseManager.h
//  AppHost
//
//  Created by liang on 2019/1/22.
//  Copyright © 2019 liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppHostResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface AHResponseManager : NSObject

/**
 自定义response类
 */
@property (nonatomic, strong, readonly) NSMutableArray *customResponseClasses;

+ (instancetype)defaultManager;

#ifdef DEBUG

/**
 获取所有注册的 Response 的接口
 
 @return 返回所有 class 支持的 methods，以 class 为 key。key 对应的数据包含所有这个 class 支持的方法
 */
- (NSDictionary *)allResponseMethods;

#endif
#pragma mark - 自定义 Response 区域
/**
 注册自定义的 Response
 
 @param cls 可以处理响应的子类 class，其符合 AppHostProtocol
 */
- (void)addCustomResponse:(Class<AppHostProtocol>)cls;

- (id<AppHostProtocol>)responseForAction:(NSString *)action withAppHost:(AppHostViewController * _Nonnull)appHost;

- (Class)responseForAction:(NSString *)action;
@end

NS_ASSUME_NONNULL_END
