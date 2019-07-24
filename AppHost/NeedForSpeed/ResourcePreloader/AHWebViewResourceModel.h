//
//  AHWebViewResourceModel.h
//  
// 这个文件目的是为 preload_resources.json 格式的注释；

//  Created by liang on 2019/7/16.
//  Copyright © 2019 Smily.Co. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface AHWebViewResourceModel : NSObject

/**
 是 html 加载时的地址，重要的是 host 部分
 */
@property (nonatomic, strong) NSString *domain;
/**
 下面的属性中，如 scripts 的地址为 相对地址，和 baseURL 拼接形成完成，如,
 baseURL = "https://hite.com".
 Scripts = ["/xm/a.js"],
 实际得到的地址是：https://hite.com/xm/a.js
 */
@property (nonatomic, strong) NSString *baseURL;

@property (nonatomic, strong) NSArray<NSString *> *scripts;

@property (nonatomic, strong) NSArray<NSString *> *styles;

@property (nonatomic, strong) NSArray<NSString *> *images;

/**
 预加载的字体，可以是数组
 */
@property (nonatomic, strong) NSArray<NSString *> *fonts;

/**
 预加载的 HTML，为了控制资源，只能加载一个。现在就下载员工精选，后期可以使用大数据做到千人千面
 */
@property (nonatomic, strong) NSString *html;
//{
//    "baseURL": "https://hite-static.wscdn.net"
//    "scripts" : [ //  详情页使用的 js 资源
//                 "/hxm/hite-wap/p/20161201/js/base-14b63f4707.js",
//                 "/hxm/hite-jssdk/common/js/jweixin-1.3.2.js",
//                 "/hxm/hite-wap/p/20161201/js/dist/index/index-c0616e142a.page.js",
//                 "/hxm/hite-wap/p/20161201/js/dist/webview/itemDetail/itemDetail-2424073b4e.page.js"
//                 ],
//    "styles": [ //  详情页使用的 js 资源
//               "/hxm/hite-wap/p/20161201/style/css/style-05d5040aba.css"
//               ],
//    "images": [ //  回到顶部的图片
//               "https://hite-static.wscdn.net/hxm/hite-wap/p/20161201/style/img/icon-normal/goToTop-f502426678.png"
//               ],
//    "fonts" : []
//                // 预加载员工精选
//    "html" : "https://hite.me/topic/v1/pub/MZee3MWrbs.html"
//}
@end

NS_ASSUME_NONNULL_END
