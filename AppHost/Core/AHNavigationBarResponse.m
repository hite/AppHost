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

- (BOOL)handleAction:(NSString *)action withParam:(NSDictionary *)paramDict
{
    if ([@"goBack" isEqualToString:action]) {
        [self onMKCustomBackAction:nil]; //调用返回的动作
    } else if ([@"setNavRight" isEqualToString:action]) {
        // 定制导航栏文字
        [self setRight:[paramDict objectForKey:@"text"]];
    } else if ([@"setNavTitle" isEqualToString:action]) {
        // 定制导航栏文字
        [self setTitle:[paramDict objectForKey:@"text"]];
    }
    return YES;
}

+ (NSDictionary<NSString *, NSString *> *)supportActionList
{
    return @{
             @"goBack" : @"1",
             @"setNavRight" : @"1",
             @"setNavTitle" : @"1"
             };
}

#pragma mark - inner

- (void)onMKCustomBackAction:(id)sender
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
        //
        [self initNavigationBarButtons];
    }else{
        [self didTapClose:sender];
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

- (void)setRight:(NSString *)title
{
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

- (void)setTitle:(NSString *)title
{
    self.appHost.navigationItem.title = title;
}

#pragma mark - event
- (void)didTapMore:(id)sender
{
    if (self.rightActionBarTitle) {
        [self sendMessageToWebPage:@"navigator.rightbar.click" param:@{}];
    }
}

@end
