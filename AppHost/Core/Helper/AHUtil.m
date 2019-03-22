//
//  AHUtil.m
//  AppHost
//
//  Created by liang on 2019/3/22.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AHUtil.h"

@implementation AHUtil

+ (BOOL)isNetworkUrl:(NSString *)url
{
    return [url hasPrefix:@"http://"] || [url hasPrefix:@"https://"] || [url hasPrefix:@"//"];
}
@end
