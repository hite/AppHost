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
             @"setNavRight" : @"1",
             @"setNavTitle" : @"1"
             };
}

#pragma mark - inner

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

- (void)setRight:(NSDictionary *)paramDict
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

- (void)setTitle:(NSDictionary *)paramDict
{
    NSString *title = [paramDict objectForKey:@"text"];
    self.appHost.navigationItem.title = title;
}

#pragma mark - event
- (void)didTapMore:(id)sender
{
    if (self.rightActionBarTitle) {
        [self fire:@"navigator.rightbar.click" param:@{}];
    }
}

@end
