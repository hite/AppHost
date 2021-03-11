//
//  AHWebViewPreLoader.h
//  
//
//  Created by liang on 2019/7/16.
//  Copyright © 2019 Smily.Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppHostEnum.h"

NS_ASSUME_NONNULL_BEGIN

// 表示目前本地的 .json 文件的版本。如果服务器较旧则不返回新配置
static const int kAHPreloadResourceVersion = 1;
extern NSString * const kPreloadResourceConfCacheKey;

typedef NSDictionary *_Nonnull(^bFetchConfig)(int version);

@interface AHWebViewPreLoader : NSObject

+ (instancetype)defaultLoader;

/**
 从服务器下载最新的配置到 ud 里. 传入当前版本，返回新的配置，配置样式如下：
 
 {
     "domain": "https://m.you.163.com",  // 是 html 加载时的地址，重要的是 host 部分

     // 下面的属性中，如 scripts 的地址为 相对地址，和 baseURL 拼接形成完成，如,
     // baseURL = "https://yanxuan-static.nosdn.127.net".
     // Scripts = ["/xm/a.js"],
     // 实际得到的地址是：https://yanxuan-static.nosdn.127.net/xm/a.js
     "baseURL": "https://yanxuan-static.nosdn.127.net",
     "scripts" : [
         "/hxm/yanxuan-wap/p/20161201/js/base-14b63f4707.js",
         "/hxm/yanxuan-jssdk/common/js/jweixin-1.3.2.js",
         "/hxm/yanxuan-wap/p/20161201/js/dist/index/index-c0616e142a.page.js",
         "/hxm/yanxuan-wap/p/20161201/js/dist/webview/itemDetail/itemDetail-2424073b4e.page.js"
     ],
     "styles": [
        "/hxm/yanxuan-wap/p/20161201/style/css/style-05d5040aba.css"
     ],
     "images": [
        "https://yanxuan-static.nosdn.127.net/hxm/yanxuan-wap/p/20161201/style/img/icon-normal/goToTop-f502426678.png"
     ],
     "fonts" : [], // 预加载的字体，可以是数组
     "html" : "" // 预加载的 HTML，为了控制资源，只能加载一个
 }
 */
- (void)updateConfig:(bFetchConfig)fetchConfig;

/**
 在新开的 window 里去下载尝试下载关键资源。
 如果有以前旧配置，使用旧配置下载。
 */
- (void)loadResources;
    
@end

NS_ASSUME_NONNULL_END
