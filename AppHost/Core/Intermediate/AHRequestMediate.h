//
//  AHRequestMediate.h
//  AppHost
//
//  Created by liang on 2019/3/22.
//  Copyright © 2019 liang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AHRequestMediate : NSObject

/**
 处理 script 和 style。图片由 WKSchemeTaskHandler 处理

 @param fileName 文件夹里的入口文件，通常是 index.html
 @param directory 包含静态资源的文件夹，可以包含图片、js、css 文件。字体文件等不支持
 @param domain 资源的相对地址，组装绝对地址时的前缀，表示此页面的加载 url。
 @param output 将所有资源都内置到 html 的文件。
 @return 是否内侧处理时，发生过错误。非 0 表示出错过，但不代码 output 是无效的。
 */
+ (int)interMediateFile:(NSString *)fileName inDirectory:(NSURL *)directory domain:(NSString *)domain output:(NSString *_Nonnull*_Nonnull)output;

@end

NS_ASSUME_NONNULL_END
