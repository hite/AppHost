//
//  MKWebViewScrollPositionManager.h

//
//  Created by liang on 02/05/2017.
//  Copyright © 2017 smilly.co All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AHWebViewScrollPositionManager : NSObject

+ (instancetype)sharedInstance;

- (void)cacheURL:(NSURL *)url position:(CGFloat)lastPosition;

- (CGFloat)positionForCacheURL:(NSURL *)url;

- (void)emptyURLCache:(NSURL *)url;

/**
 清除所有对象
 */
- (void)clearAllCache;
@end
