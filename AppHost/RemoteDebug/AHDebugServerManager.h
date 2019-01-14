//
//  AHDebugServerManager.h
//  AppHost
//
//  Created by liang on 2018/12/29.
//  Copyright © 2018 liang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AHDebugServerManager : NSObject

+ (instancetype)sharedInstance;

- (void)start;

- (void)stop;

- (void)showDebugWindow;
@end

NS_ASSUME_NONNULL_END
