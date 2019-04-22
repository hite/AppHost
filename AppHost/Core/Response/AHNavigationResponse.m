//
//  MKNavigationResponse.m

//
//  Created by liang on 05/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import "AHNavigationResponse.h"
#import "AppHostViewController.h"

@import SafariServices;

@implementation AHNavigationResponse

+ (NSDictionary<NSString *, NSString *> *)supportActionList
{
    return @{
        //增加apphost的supportTypeFunction
        @"startNewPage_" : @"4",
        @"openExternalUrl_" : @"3"
    };
}

#pragma mark - inner
ah_doc_begin(openExternalUrl_, "打开外部资源链接，可以用 SFSafariViewController 打开，也可以用系统的 Safari 浏览器打开。")
ah_doc_code(window.appHost.invoke("openExternalUrl",{"url":"https://qian.163.com"}))
ah_doc_param(url, "字符串，合法的 url 地址，包括http/mailto:/telephone:/https 前缀")
ah_doc_param(openInSafari, "布尔值，默认是 false，表示在 App 内部用 SFSafariViewController 内部打开；true 表示用系统的 Safari 浏览器打开")
ah_doc_code_expect("在 App 内的浏览器里打开了’qian.163.com‘ 页面")
ah_doc_end
- (void)openExternalUrl:(NSDictionary *)paramDict
{
    NSString *urlTxt = [paramDict objectForKey:@"url"];
    BOOL forceOpenInSafari = [[paramDict objectForKey:@"openInSafari"] boolValue];
    if (forceOpenInSafari) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlTxt] options:@{} completionHandler:nil];
    } else {
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:urlTxt]];
        [self.navigationController presentViewController:safari animated:YES completion:nil];
    }
}

- (void)insertShadowView:(NSDictionary *)paramDict
{
    AppHostViewController *freshOne = [[self.appHost.class alloc] init];
    freshOne.url = [paramDict objectForKey:@"url"];
    freshOne.pageTitle = [paramDict objectForKey:@"title"];
    freshOne.rightActionBarTitle = [paramDict objectForKey:@"actionTitle"];
    freshOne.backPageParameter = [paramDict objectForKey:@"backPageParameter"];
    //
    NSArray *viewControllers = self.navigationController.viewControllers;

    if (viewControllers.count > 0) {
        //在A->B页面里，点击返回到C，然后C返回到A，形成 A-C-B，简化下成A——C；
        NSMutableArray *newViewControllers = [viewControllers mutableCopy];
        [newViewControllers addObject:freshOne];
        freshOne.hidesBottomBarWhenPushed = YES;
        self.navigationController.viewControllers = newViewControllers;
    }
}
ah_doc_begin(startNewPage_, "新开一个 webview 页面打开目标 url。有多个参数可以控制 webview 的样式和行为")
ah_doc_code(window.appHost.invoke('startNewPage', { 'url': 'http://you.163.com/','title': 'title',
    'type': "push",
    'backPageParameter': {
        'url': 'http://qian.163.com',
        'title': 'title',
        'type': 'push'
    }
}))
ah_doc_param(url, "字符串，合法的 url 地址，包括http/mailto:/telephone:/https 前缀")
ah_doc_param(title,"当前页面的标题")
ah_doc_param(type,"新页面呈现方式，目前有两个参数可选“push”，“replace” ")
ah_doc_param(actionTitle,"顶栏右边的文字，可以响应点击事件。")
ah_doc_param(backPageParameter,"完整的一个startNewPage对应的参数； 这个参数代表了页面 c，包含这个参数的跳转执行完毕之后，到达 b 页面，此时点击返回按钮，返回到 c页面，再次点击才返回到 a 页面。即 a -> b , b -> c -> a;")
ah_doc_code_expect("新开一个 webview 打开’you.163.com‘页面，加载完毕之后，点击返回，返回到 ’qian.163.com‘ 页面")
ah_doc_end
- (void)startNewPage:(NSDictionary *)paramDict
{
    AppHostViewController *freshOne = [[self.appHost.class alloc] init];
    freshOne.url = [paramDict objectForKey:@"url"];
    freshOne.pageTitle = [paramDict objectForKey:@"title"];
    freshOne.rightActionBarTitle = [paramDict objectForKey:@"actionTitle"];

    freshOne.backPageParameter = [paramDict objectForKey:@"backPageParameter"];
    NSString *loadType = [paramDict objectForKey:@"type"];
    if (freshOne.backPageParameter) {
        //额外插入一个页面；
        [self insertShadowView:freshOne.backPageParameter];
    }
    if ([@"replace" isEqualToString:loadType]) {
        NSArray *viewControllers = self.navigationController.viewControllers;

        if (viewControllers.count > 1) {
            // replace的目的就是调整到新的list页面；需要替换旧list和新的回复页面；
            NSMutableArray *newViewControllers = [[viewControllers subarrayWithRange:NSMakeRange(0, [viewControllers count] - 2)] mutableCopy];
            [newViewControllers addObject:freshOne];
            freshOne.hidesBottomBarWhenPushed = YES;
            [self.navigationController setViewControllers:newViewControllers animated:YES];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        [self.navigationController pushViewController:freshOne animated:YES];
    }
}
@end
