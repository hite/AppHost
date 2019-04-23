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
             @"toast_" : @"1",
             @"showLoading_" : @"1",
             @"hideLoading" : @"1",
             @"enablePageBounce_" : @"1"
             };
}

#pragma mark - inner

ah_doc_begin(showLoading_, "loading 的 HUD 动画，这里是AppHost默认实现显示。")
ah_doc_param(text, "字符串，设置和 loading 动画一起显示的文案")
ah_doc_code(window.appHost.invoke("showLoading",{"text":"请稍等..."}))
ah_doc_code_expect("在屏幕上出现 loading 动画，多次调用此接口，不应该出现多个")
ah_doc_end
- (void)showLoading:(NSDictionary *)paramDict
{
    NSString *tip = [paramDict objectForKey:@"text"];
    NSLog(@"Info: 正在显示 Loading 提示: %@，请使用本 App 的的 HUD 接口实现，以保持一致体验", tip);
}

ah_doc_begin(hideLoading, "隐藏 loading 的 HUD 动画，这里是AppHost默认实现显示。")
ah_doc_code(window.appHost.invoke("hideLoading"))
ah_doc_code_expect("在有 loading 动画的情况下，调用此接口，会隐藏 loading。")
ah_doc_end
- (void)hideLoading
{
    NSLog(@"Info: 关闭显示 HUD ，请使用本 App 的的 HUD 接口实现，以保持一致体验");
}

ah_doc_begin(toast_, "显示居中的提示，过几秒后消失，这里是AppHost默认实现显示。")
ah_doc_param(text, "字符串，显示的文案，可多行")
ah_doc_code(window.appHost.invoke("toast",{"text":"请稍等..."}))
ah_doc_code_expect("在屏幕上出现 '请稍等...'，多次调用此接口，不应该出现多个")
ah_doc_end
- (void)toast:(NSDictionary *)paramDict
{
    CGFloat delay = [[paramDict objectForKey:@"delay"] floatValue];
    [self showTextTip:[paramDict objectForKey:@"text"] delay:delay];
}

- (void)showTextTip:(NSString *)tip delay:(CGFloat)delay
{
    NSLog(@"Info: 正在显示 Toast 提示: %@, %f秒消失，请使用本 App 的的 HUD 接口实现，以保持一致体验", tip, delay);
}

ah_doc_begin(enablePageBounce_, "容许触发 webview 下拉弹回的动画，传入 false 表示不容许；这个效果是 iOS 独有的")
ah_doc_param(enabled, "布尔值， true 表示开启，false 表示关闭")
ah_doc_code(window.appHost.invoke("enablePageBounce",{"enabled":false}))
ah_doc_code_expect("本测试页面在滑动到底部或顶部时，没有 bounce 效果，在执行之前，尝试滑动底部，会出现 bounce 效果。")
ah_doc_end
- (void)enablePageBounce:(NSDictionary *)paramDict
{
    BOOL bounce = [[paramDict objectForKey:@"enabled"] boolValue];
    self.webView.scrollView.bounces = bounce;
}

@end
