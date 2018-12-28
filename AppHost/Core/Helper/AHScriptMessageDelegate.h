//
//  MKScriptMessageDelegate.h

//
//  Created by liang on 16/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import <Foundation/Foundation.h>

@import WebKit;

@interface AHScriptMessageDelegate : NSObject<WKScriptMessageHandler>

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate;

@end
