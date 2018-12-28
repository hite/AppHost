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
 * <B> 辅助方法，转发到 appHost 的接口 </B>
 */
- (void)callbackFunctionOnWebPage:(NSString *)actionName param:(NSDictionary *)paramDict;

/**
 * <B> 辅助方法，转发到 appHost 的接口 </B>
 */
- (void)sendMessageToWebPage:(NSString *)actionName param:(NSDictionary *)paramDict;

@end
