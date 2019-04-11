//
//  AHJSCoreManager.m
//  AppHost
//
//  Created by liang on 2019/4/11.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AHJSCoreManager.h"
#import "AHUtil.h"

@implementation AHJSCoreManager

+(instancetype)defaultManager{
    static AHJSCoreManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [AHJSCoreManager new];
    });
    
    return _instance;
}

@end
