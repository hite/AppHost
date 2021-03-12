//
//  AHLogProvider.h
//  AppHost
//
//  Created by hite on 2021/3/12.
//  Copyright © 2021 liang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AHLogProviderProtocol <NSObject>

- (void)logAction:(NSString *)actionName tags:(NSDictionary *)tags fields:(NSDictionary *)fields;

@end

NS_ASSUME_NONNULL_END
