//
//  AHDebugResponse.h
//  AppHost
//
//  Created by liang on 2019/1/22.
//  Copyright © 2019 liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppHostResponse.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *kAppHostTestCaseFileName = @"testcase.html";
@interface AHDebugResponse : AppHostResponse

+ (void)setupDebugger;

@end

NS_ASSUME_NONNULL_END
