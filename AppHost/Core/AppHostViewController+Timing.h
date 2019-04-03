//
//  AppHostViewController+Timing.h
//  AppHost
//
//  Created by liang on 2019/4/2.
//  Copyright © 2019 liang. All rights reserved.
//

#import <AppHost/AppHost.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *kAppHostTimingLoadRequest = @"loadRequest";
static NSString *kAppHostTimingWebViewInit = @"webViewInit";
static NSString *kAppHostTimingDidFinishNavigation = @"didFinishNavigation";
static NSString *kAppHostTimingDecidePolicyForNavigationAction = @"decidePolicyForNavigationAction";
static NSString *kAppHostTimingAddUserScript = @"addUserScript";
@interface AppHostViewController (Timing)

/**
 保存所有 mark 的起点数据。
 */
@property (nonatomic, strong) NSMutableDictionary *marks;

/**
 记录起点

 @param markName 起点的别名，用来和后面 mearsue 配合使用
 */
- (void)mark:(NSString *)markName;

/**
 计算从此时到 markName 别打标记时的时间耗时

 */
- (void)measure:(NSString *)endMarkName to:(NSString *)startMark;

@end

NS_ASSUME_NONNULL_END
