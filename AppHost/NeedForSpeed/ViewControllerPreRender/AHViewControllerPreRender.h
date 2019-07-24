//
//  ViewControllerPreRender.h
//  ViewControllerPreRender
//
//  Created by liang on 2019/5/29.
//  Copyright © 2019 liang. All rights reserved.
// 本类来自 https://github.com/hite/ViewControllerPreRender
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AppHostViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AHViewControllerPreRender : NSObject

#ifdef DEBUG
/**
 预加载的 window，和主屏幕的偏移，默认是 0，widthOffset = 20，表示，可以看到 20px 的预加载 window；
 */
@property (nonatomic, assign) CGFloat widthOffset;
#endif

+ (instancetype)defaultRender;

/**
  获取一个已经预热好的 VC，然后在 block 回调中，push 或者 present

 @param viewControllerClass 需求预热的 类
 @param block 本 block 中会返回一个预热好的 由调用者决定，push 或者 present
 */
- (void)getRenderedViewController:(Class)viewControllerClass completion:(void (^)(UIViewController *vc))block;

/**
 获取一个为 WebView 加载定制的预加载 VC，在 block 回调中，push 或者 present

 @param viewControllerClass 需求预热的类, 必须是AppHostViewController类或者子类
 @param url 需要加载的 url
 @param block 拿到已经预热好的 VC 后，额外的处理逻辑；
 */
- (void)getWebViewController:(Class)viewControllerClass preloadURL:(NSString *)url completion:(void (^)(AppHostViewController *vc))block;
@end

NS_ASSUME_NONNULL_END
