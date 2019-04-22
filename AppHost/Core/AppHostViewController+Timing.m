//
//  AppHostViewController+Timing.m
//  AppHost
//
//  Created by liang on 2019/4/2.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AppHostViewController+Timing.h"
#import <objc/runtime.h>

@implementation AppHostViewController (Timing)

#ifdef AH_DEBUG

- (void)mark:(NSString *)markName
{
    NSMutableDictionary *marks = self.marks;
    if (marks == nil) {
        marks = [NSMutableDictionary dictionaryWithCapacity:10];
        self.marks = marks;
    }
    
    [marks setObject:@(NOW_TIME) forKey:markName];
}

- (void)measure:(NSString *)endMarkName to:(NSString *)startMark;
{
    long long time = [[self.marks objectForKey:startMark] longLongValue];
    AHLog(@"[Timing] %@ ~ %@ 耗时共 %f",endMarkName, startMark, NOW_TIME - time);
}
#else

- (void)mark:(NSString *)markName{};
- (void)measure:(NSString *)endMarkName to:(NSString *)startMark{};

#endif

#pragma mark - getter

- (void)setMarks:(NSMutableDictionary *)marks
{
    objc_setAssociatedObject(self, @selector(setMarks:), marks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)marks
{
    return objc_getAssociatedObject(self, @selector(setMarks:));
}

@end
