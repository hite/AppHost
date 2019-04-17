//
//  AppHostViewController+Progressor.h
//  AppHost
//
//  Created by liang on 2019/3/23.
//  Copyright © 2019 liang. All rights reserved.
//

#import <AppHost/AppHost.h>

@interface AppHostViewController (Progressor)

@property (nonatomic, strong) NSTimer *clearProgressorTimer;

@property (nonatomic, strong) UIProgressView *progressorView;

- (void)startProgressor;

- (void)stopProgressor;
#pragma mark - lifecycle
- (void)setupProgressor;
- (void)teardownProgressor;

@end

