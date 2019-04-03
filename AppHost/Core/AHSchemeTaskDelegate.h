//
//  AHSchemeTaskResponse.h
//  AppHost
//
//  Created by liang on 2018/12/29.
//  Copyright © 2018 liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppHostEnum.h"

@import WebKit;

typedef NSData*_Nonnull(^bSchemeTaskHandler)(WKWebView *_Nonnull, id<WKURLSchemeTask> _Nonnull, NSString *_Nullable * _Nullable mime);

NS_ASSUME_NONNULL_BEGIN

@interface AHSchemeTaskDelegate : NSObject <WKURLSchemeHandler>

/**
 添加自定义的处理逻辑
 */
- (void)addHandler:(bSchemeTaskHandler)handler forDomain:(NSString */* js */)domain;

@end

NS_ASSUME_NONNULL_END
