//
//  AppHostViewController+Utils.h
//  AppHost
//
//  Created by liang on 2019/3/23.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AppHostViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppHostViewController (Utils)

- (NSDictionary *)supportListByNow;

- (void)showTextTip:(NSString *)text;

- (void)showTextTip:(NSString *)text hideAfterDelay:(CGFloat)delay;

- (void)dealWithViewHistory;

- (void)popOutImmediately;

- (BOOL)isExternalSchemeRequest:(NSString *)url;

- (BOOL)isItmsAppsRequest:(NSString *)url;

- (void)logRequestAndResponse:(NSString *)str type:(NSString *)type;

@end

NS_ASSUME_NONNULL_END
