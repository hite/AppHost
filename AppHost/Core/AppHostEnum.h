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

// 定义 oc-doc，为自动化生成测试代码和自动化注释做准备
// 凡是可能多行的文字描述都用 @result，而不是@#result

#define ah_concat(A, B) A##B
#define ah_doc_log_prefix @"ah_doc_for_"

#define ah_doc_begin(log, desc) +(NSDictionary *)ah_concat(ah_doc_for_, log)\
{\
return @{\
@"discuss":@desc,

#define ah_doc_code(code) "code":@#code,
//ah_doc_code_result 是为了给 ah_doc_code 的代码执行后结果的描述，
#define ah_doc_code_result(result) "codeResult":@result,

#define ah_doc_param(paramName, paramDesc) "param":@{@#paramName:@paramDesc},

#define ah_doc_return(type, desc) "return":@{@#type:@desc}

#define ah_doc_end };\
}
// oc-doc 结束

#endif /* AppHostEnum_h */

#ifdef AH_VIEWCONTROLLER_BASE
    #define AH_VC_BASE_NAME AH_VIEWCONTROLLER_BASE
#else
    #define AH_VC_BASE_NAME UIViewController
#endif

#define NOW_TIME [[NSDate date] timeIntervalSince1970] * 1000

// 为了解决 webview Cookie 而需要提前加载的页面
extern NSString * _Nonnull kFakeCookieWebPageURLWithQueryString;
// 设置进度条的颜色，如 "0xff00ff";
extern long long kWebViewProgressTintColorRGB;
// 是否打开 debug server 的日志。
extern BOOL kGCDWebServer_logging_enabled;

static NSString * _Nonnull kAHLogoutNotification = @"kAHLogoutNotification";
static NSString * _Nonnull kAHLoginSuccessNotification = @"kAHLoginSuccessNotification";

static NSString * _Nonnull kAppHostEventDismissalFromPresented = @"kAppHostEventDismissalFromPresented";
// core
static NSString * _Nonnull kAHActionKey = @"action";
static NSString * _Nonnull kAHParamKey = @"param";
