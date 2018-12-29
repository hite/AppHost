//
//  AppHostEnum.h
//  AppHost
//
//  Created by liang on 2018/12/28.
//  Copyright © 2018 liang. All rights reserved.
//

#ifndef AppHostEnum_h
#define AppHostEnum_h

// 创建一个超级厉害的宏，https://www.jianshu.com/p/cbb6b71d925d
// 在 debug 模式下打印带前缀的日志，非 debug 模式下，不输出。
#if !defined(AHLog)
#ifdef DEBUG
#define AHLog(format, ...)  do {\
(NSLog)((@"[AppHost] " format), ##__VA_ARGS__); \
} while (0)
#else
#define AHLog(format, ...)
#endif
#endif

//获取设备的物理高度
#define AH_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
//获取设备的物理宽度
#define AH_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define AH_IS_SCREEN_HEIGHT_X (AH_SCREEN_HEIGHT == 812.0f || AH_SCREEN_HEIGHT == 896.0f)

#define AH_PURE_NAVBAR_HEIGHT 44 //单纯的导航的高度
#define AH_NAVIGATION_BAR_HEIGHT (AH_PURE_NAVBAR_HEIGHT + [[UIApplication sharedApplication] statusBarFrame].size.height) //顶部（导航+状态栏）的高度

#define AHColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0x0000FF))/255.0 \
alpha:1.0]

#define AHColorFromRGBA(rgbValue, alphaValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0x0000FF))/255.0 \
alpha:alphaValue]

#endif /* AppHostEnum_h */

// 为了解决 webview Cookie 而需要提前加载的页面
extern NSString * _Nonnull kFakeCookieWebPageURLWithQueryString;
// 设置进度条的颜色，如 "0xff00ff";
extern long long kWebViewProgressTintColorRGB;

static NSString *kAHLogoutNotification = @"kAHLogoutNotification";
static NSString *kAHLoginSuccessNotification = @"kAHLoginSuccessNotification";

static NSString *kAppHostEventDismissalFromPresented = @"kAppHostEventDismissalFromPresented";
