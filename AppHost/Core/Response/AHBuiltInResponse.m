//
//  MKBuiltInResponse.m

//
//  Created by liang on 06/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import "AHBuiltInResponse.h"
#import "AppHostViewController.h"

@implementation AHBuiltInResponse

+ (NSDictionary<NSString *, NSString *> *)supportActionList
{
    return @{
             @"toast" : @"1",
             @"showLoading" : @"1",
             @"hideLoading" : @"1",
             @"pageBounceEnabled" : @"1"
             };
}

#pragma mark - inner
- (void)hideLoading
{
    NSLog(@"Info: 关闭显示 HUD ，请使用本 App 的的 HUD 接口实现，以保持一致体验");
}

- (void)showLoading:(NSDictionary *)paramDict
{
    NSString *tip = [paramDict objectForKey:@"text"];
    NSLog(@"Info: 正在显示 Loading 提示: %@，请使用本 App 的的 HUD 接口实现，以保持一致体验", tip);
}

- (void)toast:(NSDictionary *)paramDict
{
    CGFloat delay = [[paramDict objectForKey:@"delay"] floatValue];
    [self showTextTip:[paramDict objectForKey:@"text"] delay:delay];
}

- (void)showTextTip:(NSString *)tip delay:(CGFloat)delay
{
    NSLog(@"Info: 正在显示 Toast 提示: %@, %f秒消失，请使用本 App 的的 HUD 接口实现，以保持一致体验", tip, delay);
}

- (void)enablePageBounce:(NSDictionary *)paramDict
{
    BOOL bounce = [[paramDict objectForKey:@"enabled"] boolValue];
    self.webView.scrollView.bounces = bounce;
}


@end
