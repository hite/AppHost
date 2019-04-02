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

#pragma mark - like private

- (void)insertData:(NSDictionary *)json intoPageWithVarName:(NSString *)appProperty;

- (void)executeJavaScriptString:(NSString *)javaScriptString;

- (void)injectScriptsToUserContent:(WKUserContentController *)userContent;

@end

NS_ASSUME_NONNULL_END
