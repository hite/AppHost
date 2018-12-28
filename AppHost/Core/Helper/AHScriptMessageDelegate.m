//
//  MKScriptMessageDelegate.m

//
//  Created by liang on 16/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import "AHScriptMessageDelegate.h"

@interface AHScriptMessageDelegate()

@property (nonatomic, weak) id<WKScriptMessageHandler> scriptDelegate;

@end

@implementation AHScriptMessageDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate
{
    self = [super init];
    if (self) {
        _scriptDelegate = scriptDelegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

- (void)dealloc
{
    NSLog(@"MKScriptMessageDelegate dealloc");
}

@end
