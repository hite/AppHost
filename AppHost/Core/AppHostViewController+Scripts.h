//
//  AppHostViewController+Scripts.h
//  AppHost
//
//  Created by liang on 2019/3/23.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AppHostViewController.h"

@class WKUserContentController;

NS_ASSUME_NONNULL_BEGIN

@interface AppHostViewController (Scripts)

/**
 * <B> 调用 callback 的函数，这个函数是 js 端调用方法时，注册在 js 端的 block。
 * 这里传入的第一个参数是 和这个 js 端 block 相关联的 key。js 根据这个 key 找到这个 block 并且执行 </B>
 */
- (void)fireCallback:(NSString *)actionName param:(NSDictionary *)paramDict;
/**
 *  对应，监听了事件的接口的调用
 */
- (void)fire:(NSString *)actionName param:(NSDictionary *)paramDict;

/**
 无返回值的执行 js 代码
 
 @param javaScriptString 可执行的 js 代码
 */
- (void)executeJavaScriptString:(NSString *)javaScriptString;
/**
 需要返回值的 js 代码。可以返回例如 document 之类的，JSValue 无法映射的数据对象
 
 @param jsCode 可执行的 js 代码，注意：如果有引号，需要使用双引号。
 @param completion 返回的回调
 */
- (void)evalExpression:(NSString *)jsCode completion:(void (^)(id result, NSString *err))completion;
/**
 设置在 userscript 里要加载的脚本。如果已经打开了 webview，则这些设置需要在下次执行时生效

 @param script 注入的脚本，string\ url,两种类型
 @param injectTime 注入时机
 @param key 这段脚本的标识，为了后续的删除
 */
+ (void)prepareJavaScript:(id)script when:(WKUserScriptInjectionTime)injectTime key:(NSString *)key;
+ (void)removeJavaScriptForKey:(NSString *)key;

#pragma mark - like private
- (void)insertData:(NSDictionary *)json intoPageWithVarName:(NSString *)appProperty;

- (void)injectScriptsToUserContent:(WKUserContentController *)userContent;

@end

NS_ASSUME_NONNULL_END
