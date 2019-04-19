//
//  AHDebugWindow.h
//  AppHost
//
//  Created by admin on 14/1/2019.
//  Copyright © 2019 liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AHDebugViewController;

@protocol AHDebugViewDelegate <NSObject>

- (void)onCloseWindow:(AHDebugViewController *)viewController;

- (void)fetchData:(AHDebugViewController *)viewController completion:(void (^)(NSArray<NSString *> *))completion;

@end

@interface AHDebugViewController : UIViewController

@property (nonatomic, weak) id<AHDebugViewDelegate> debugViewDelegate;

- (void)showNewLine:(NSArray<NSString *> *)line;

- (void)onWindowHide;
- (void)onWindowShow;

@end

NS_ASSUME_NONNULL_END
