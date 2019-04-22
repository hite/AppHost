//
//  MKNavigationBarResponse.m

//
//  Created by liang on 05/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import "AHNavigationBarResponse.h"
#import "AppHostViewController.h"

@interface AHNavigationBarResponse ()

// 以下是 short hand，都是从appHost 上的属性
@property (nonatomic, copy) NSString *rightActionBarTitle;

@end

@implementation AHNavigationBarResponse

+ (NSDictionary<NSString *, NSString *> *)supportActionList
{
    return @{
             @"goBack" : @"1",
             @"setNavRight_" : @"1",
             @"setNavTitle_" : @"1"
             };
}

#pragma mark - inner
ah_doc_begin(goBack, "h5 页面的返回，如果可以返回到上一个 h5 页面则返回上一个 h5，否则退出 webview 页面，如果是弹出的 webview，还可能关闭这个 presented 的 ViewController。")
ah_doc_code(window.appHost.invoke("goBack"))
ah_doc_code_expect("会关闭本页面")
ah_doc_end
- (void)goBack
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
        //
        [self initNavigationBarButtons];
    }else{
        [self didTapClose:nil];
    }
}

- (void)didTapClose:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)initNavigationBarButtons
{
    if (self.appHost.fromPresented) {
        UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain  target:self action:@selector(dismissViewController:)];
        self.appHost.navigationItem.leftBarButtonItem = close;
        self.appHost.navigationItem.accessibilityHint = @"关闭 AppHost 弹窗";
    }
}

- (void)dismissViewController:(id)sender
{
    [self.appHost dismissViewControllerAnimated:YES completion:nil];
    if ([self.appHost.appHostDelegate respondsToSelector:@selector(onResponseEventOccurred:response:)]) {
        [self.appHost.appHostDelegate onResponseEventOccurred:kAppHostEventDismissalFromPresented response:self];
    }
}

#pragma mark - nav
ah_doc_begin(setNavRight_, "h5 页面的返回，如果可以返回到上一个 h5 页面则返回上一个 h5，否则退出 webview 页面")
ah_doc_code(window.appHost.on('navigator.rightbar.click',function(p){alert('你点击了'+p.text+'按钮')});window.appHost.invoke("setNavRight",{"text":"发射"}))
ah_doc_param(text, "字符串，右上角按钮的文案")
ah_doc_code_expect("右上角出现一个’发射‘按钮，点击这个按钮，会触发 h5 对右上角按钮的监听。表现：弹出 alert，文案是’你点击了发射按钮‘。")
ah_doc_end
- (void)setNavRight:(NSDictionary *)paramDict
{
    NSString *title = [paramDict objectForKey:@"text"];
    self.rightActionBarTitle = title;
    UIBarButtonItem *rightBarButton = nil;
    
    if (self.rightActionBarTitle.length > 0) {
        UIButton *rightBtn = [UIButton new];
        [rightBtn setTitle:self.rightActionBarTitle forState:UIControlStateNormal];
        [rightBtn setTitleColor:AHColorFromRGB(0x333333) forState:UIControlStateNormal];
        [rightBtn addTarget:self action:@selector(didTapMore:) forControlEvents:UIControlEventTouchUpInside];
        [rightBtn sizeToFit];
        
        rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
    }
    self.appHost.navigationItem.rightBarButtonItem = rightBarButton;
}

ah_doc_begin(setNavTitle_, "设置 webview 页面中间的标题")
ah_doc_code(window.appHost.invoke("setNavTitle",{"text":"酒泉卫星发射中心"}))
ah_doc_param(text, "字符串，整个 ViewController 的标题")
ah_doc_code_expect("标题栏中间出现设置的文案，’酒泉卫星发射中心‘")
ah_doc_end
- (void)setNavTitle:(NSDictionary *)paramDict
{
    NSString *title = [paramDict objectForKey:@"text"];
    self.appHost.navigationItem.title = title;
}

#pragma mark - event
- (void)didTapMore:(id)sender
{
    if (self.rightActionBarTitle) {
        [self fire:@"navigator.rightbar.click" param:@{@"text": self.rightActionBarTitle}];
    }
}

@end
