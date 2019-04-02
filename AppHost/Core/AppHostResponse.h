//
//  MKAppHostResponse.h

//
//  Created by liang on 05/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppHostProtocol.h"
#import "AppHostEnum.h"

@interface AppHostResponse : NSObject <AppHostProtocol>

/**
 * <B> 调用 callback 的函数，这个函数是 js 端调用方法时，注册在 js 端的 block。
 * 这里传入的第一个参数是 和这个 js 端 block 相关联的 key。js 根据这个 key 找到这个 block 并且执行 </B>
 */
- (void)fireCallback:(NSString *)callbackKey param:(NSDictionary *)paramDict;

/**
 * <B> 辅助方法，转发到 appHost 的接口 </B>
 */
- (void)fire:(NSString *)actionName param:(NSDictionary *)paramDict;

@end
