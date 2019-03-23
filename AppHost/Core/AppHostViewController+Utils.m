//
//  AppHostViewController+Utils.m
//  AppHost
//
//  Created by liang on 2019/3/23.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AppHostViewController+Utils.h"
#import "AppHostViewController+Dispatch.h"
#import "AHWebViewScrollPositionManager.h"
#import "AHResponseManager.h"

@implementation AppHostViewController (Utils)

#pragma mark - supportType
- (NSDictionary *)supportListByNow
{
    //人肉维护支持列表；
    NSMutableDictionary *supportedFunctions = [@{
                                                 //增加apphost的supportTypeFunction
                                                 @"pageshow" : @"2",
                                                 @"pagehide" : @"2"
                                                 } mutableCopy];
    // 内置接口
    // 各个response 的 supportFunction
    [[AHResponseManager defaultManager].customResponseClasses enumerateObjectsUsingBlock:^(Class resp, NSUInteger idx, BOOL * _Nonnull stop) {
        [supportedFunctions addEntriesFromDictionary:[resp supportActionList]];
    }];
    
    
    NSMutableDictionary *lst = [NSMutableDictionary dictionaryWithCapacity:10];
    [lst setObject:supportedFunctions forKey:@"supportFunctionType"];
    
    NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithCapacity:10];
    if (AH_IS_SCREEN_HEIGHT_X) {
        [appInfo setObject:@{ @"iPhoneXVersion" : @"1" } forKey:@"iPhoneXInfo"];
    }
    
    [lst setObject:appInfo forKey:@"appInfo"];
    return lst;
}

#pragma mark - shim

- (void)showTextTip:(NSString *)text
{
    [self showTextTip:text hideAfterDelay:2.f];
}

- (void)showTextTip:(NSString *)text hideAfterDelay:(CGFloat)delay
{
    [self callNative:@"showTextTip" parameter:@{
                                                @"text" : text ?: @"<空>",
                                                @"hideAfterDelay" : @(delay > 0 ?: 2.f)
                                                }];
}

#pragma mark - view history
- (void)dealWithViewHistory
{
    if (self.disableScrollPositionMemory) {
        return;
    }
    
    NSURL *url = self.webView.URL;
    UIScrollView *sv = self.webView.scrollView;
    CGFloat oldY = [[AHWebViewScrollPositionManager sharedInstance] positionForCacheURL:url];
    if (oldY != sv.contentOffset.y) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            sv.contentOffset = CGPointMake(0, oldY);
        });
    }
}


#pragma mark - scrollview delegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.disableScrollPositionMemory) {
        return;
    }
    CGFloat y = scrollView.contentOffset.y;
    NSLog(@"contentOffset.y = %.2f", y);
    [[AHWebViewScrollPositionManager sharedInstance] cacheURL:self.webView.URL position:y];
}

#pragma mark - utils

- (void)popOutImmediately
{
    if (self.fromPresented) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (BOOL)isExternalSchemeRequest:(NSString *)url
{
    NSArray<NSString *> *prefixs = @[ @"http://", @"https://"];
    BOOL __block external = YES;
    
    [prefixs enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([url hasPrefix:obj]) {
            external = NO;
            *stop = YES;
        }
    }];
    
    return external;
}

static NSString *const kAHRequestItmsApp = @"itms-apps://";
- (BOOL)isItmsAppsRequest:(NSString *)url
{
    // itms-appss://itunes.apple.com/cn/app/id992055304
    // https://itunes.apple.com/cn/app/id992055304
    NSArray<NSString *> *prefixs = @[ kAHRequestItmsApp, @"https://itunes.apple.com", @"itms-appss://", @"itms-services://", @"itmss://" ];
    BOOL __block pass = NO;
    
    [prefixs enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([url hasPrefix:obj]) {
            pass = YES;
            *stop = YES;
        }
    }];
    
    return pass;
}

- (void)logRequestAndResponse:(NSString *)str type:(NSString *)type
{
    NSInteger limit = 500;
    if (str.length > limit) {
        AHLog(@"debug type: %@ , url : %@", type, [str substringToIndex:limit]);
    } else {
        AHLog(@"debug type: %@ , url : %@", type, str);
    }
}

@end
