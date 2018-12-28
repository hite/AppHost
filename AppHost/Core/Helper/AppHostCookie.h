//
//  MKAppHostCookie.h

//
//  Created by liang on 06/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import <Foundation/Foundation.h>

@import WebKit;

@interface AppHostCookie : NSObject
/**
 针对处理cookie发生变化时的调用。如登录成功后的页面内跳转
 */
+ (NSMutableArray<NSString *> *)cookieJavaScriptArray;

+ (WKProcessPool *)sharedPoolManager;

// 以下和 cookie 同步相关
+ (void)setLoginCookieHasBeenSynced:(BOOL)synced;

+ (BOOL)loginCookieHasBeenSynced;
@end
