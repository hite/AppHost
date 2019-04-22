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
#ifdef AH_DEBUG
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
// 定义多行文字
#define ah_ml(str) @#str
//# 字段含义说明；
//#   1. name 表示接口名称，是 invoke 或者 call 之后的第一个参数
//#   2. code 调用实例。注意，这里必须是可以真正运行的代码，因为这个字段会被作为测试用例，直接运行
//#           特别注意，当这个 hash 对象有 expectFunc 字段时，
//#           需要在 code 的源码里有回调去验证执行的结果是否符合预期。需要调用 window.report 接口。详细用例可参考 LocalStorage.getItem 字条
//#   3. discuss 描述接口的作用
//#   4. expect 表示执行 code 源码之后的效果或者结果，文字描述
//#   5. expectFunc ，可选项，表示 code 之后，可验证的数据，用于 自动化测试框架验证。
//#   6. autoTest ，可选项，默认为 false，表示可以响应自动化测试。false 表示不能响应，需要手动验证。 false 多见于那些页面跳转的逻辑接口
//
//# 注意其中，code 字段里的调用如果有 callback function，则需要自行验证，并且把结果,
//# 使用 window.report(res, eleId) 报告，其中可以用 eleId 参数。此参数代表测试用例关联的元素, 用来显示测试结果。
//#     其中，res 是 true、false、finish、tapApp、navBack、swipeDown、swipeLeft、sleep, 等的枚举值
//#     eleId 是 当前测试用例所在的行数。传入 eleId，无需修改。

#define ah_concat(A, B) A##B
#define ah_doc_log_prefix @"ah_doc_for_"
#define ah_doc_selector(name) NSSelectorFromString([NSString stringWithFormat:@"%@%@", ah_doc_log_prefix, name])
// 定义 oc-doc，为自动化生成测试代码和自动化注释做准备
// 凡是可能多行的文字描述都用 @result,传入的数据需要有双引号，而不是@#result

#define ah_doc_begin(signature, desc) +(NSDictionary *)ah_concat(ah_doc_for_, signature)\
{\
NSMutableArray *lst = [NSMutableArray arrayWithCapacity:3];\
NSMutableDictionary *docs = [@{\
@"name":@#signature,\
@"discuss":@desc\
} mutableCopy];
#define ah_doc_code(code) [docs setObject:@#code forKey:@"code"];

#define ah_doc_code_expect(result) [docs setObject:@result forKey:@"expect"];
#define ah_doc_code_expectFunc(result) [docs setObject:@result forKey:@"expectFunc"];
#define ah_doc_code_autoTest(result) [docs setObject:@result forKey:@"autoTest"];

#define ah_doc_param(field, desc) [lst addObject:@{@#field:@desc}];

#define ah_doc_return(type, desc) [docs setObject:@{@#type:@desc} forKey:@"return"];

#define ah_doc_end if(lst.count > 0){\
        [docs setObject:lst forKey:@"param"];\
    }\
    return docs;\
}
// oc-doc 结束

#endif /* AppHostEnum_h */

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
