//
//  MKURLChecker.h
//
//  Created by hite on 4/22/16.
//  Copyright © 2016 smilly.co. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 *  定义授权的类型
 */
typedef NS_ENUM(NSUInteger, AHAuthorizationType) {

    AHAuthorizationTypeSchema,
    /**
     *  是否容许调用apphost接口
     */
    AHAuthorizationTypeAppHost
};

@interface AHURLChecker : NSObject

+ (instancetype)sharedManager;

/**
 *  检查是否容许url访问authype的接口
 *
 *  @param url      NSURL对象
 *  @param authType 授权类型的枚举
 *
 *  @return 是否容许，yes表示容许
 */
- (BOOL)checkURL:(NSURL *)url forAuthorizationType:(AHAuthorizationType)authType;


@end
