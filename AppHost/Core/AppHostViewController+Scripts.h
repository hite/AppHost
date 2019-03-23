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
 *  对应传入了匿名对象的接口的调用
 *
 */
- (void)callbackFunctionOnWebPage:(NSString *)actionName param:(NSDictionary *)paramDict;
/**
 *  对应，监听了事件的接口的调用
 */
- (void)sendMessageToWebPage:(NSString *)actionName param:(NSDictionary *)paramDict;

#pragma mark - like private

- (void)insertData:(NSDictionary *)json intoPageWithVarName:(NSString *)appProperty;

- (void)executeJavaScriptString:(NSString *)javaScriptString;

- (void)injectScriptsToUserContent:(WKUserContentController *)userContent;

@end

NS_ASSUME_NONNULL_END
