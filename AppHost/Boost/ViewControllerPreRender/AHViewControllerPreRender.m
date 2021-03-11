//
//  ViewControllerPreRender.m
//  ViewControllerPreRender
//
//  Created by liang on 2019/5/29.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AHViewControllerPreRender.h"

@interface AHViewControllerPreRender ()

@property (nonatomic, strong) UIWindow *windowNO2;
/**
 已经被渲染过后的 ViewController，池子,在必要时候 purge 掉
 */
@property (nonatomic, strong) NSMutableDictionary *renderedViewControllers;

@end

static AHViewControllerPreRender *_myRender = nil;
@implementation AHViewControllerPreRender

+ (instancetype)defaultRender{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _myRender = [AHViewControllerPreRender new];
        _myRender.renderedViewControllers = [NSMutableDictionary dictionaryWithCapacity:3];
        // 增加一个监听，当内存紧张时，丢弃这些预加载的对象不会造成功能错误，
        // 这样也要求 UIViewController 的 dealloc 都能正确处理资源释放
        [[NSNotificationCenter defaultCenter] addObserver:_myRender
                                                 selector:@selector(dealMemoryWarnings:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    });
    return _myRender;
}

- (void)setupWindowNO2 {
    if (_windowNO2 == nil) {
        CGRect full = [UIScreen mainScreen].bounds;
        // 对于 no2 的尺寸多少为合适。我自己做了下实验
        // 这里设置的尺寸会影响被缓存的 VC 实例的尺寸。但在预热好的 VC 被添加到当前工作的 navigation stack 时，它的 View 的尺寸是正确的和 no2 的尺寸。
        // 同样的，在被添加到 navigation stack 时，会触发 viewLayoutMarginsDidChange 事件。
        // 而且对于内存而言，尺寸越小内存占用越少，理论上 （1，1，1，1） 的 no2 有能达到预热 VC 的效果。
        // 但是有些 view 不是被 presented 或者 pushed，而是作为子 ViewController 的子 view 来渲染界面的。这需要 view 有正确的尺寸。
        // 所以这里预先设置将来真正展示时的尺寸，减少 resize、和作为子 ViewController 使用时出错，在本 demo 中，默认大部分的尺寸是全屏。
        CGFloat gap = 0;
#ifdef DEBUG
        gap = self.widthOffset;
#endif
        UIWindow *no2 = [[UIWindow alloc] initWithFrame:CGRectOffset(full, CGRectGetWidth(full) - gap, 0)];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[UIViewController new]];
        no2.rootViewController = nav;
        no2.hidden = NO;// 必须是显示的 window，才会触发预热 ViewController，隐藏的 window 不可用。但是和是否在屏幕可见没关系
        no2.windowLevel = UIWindowLevelStatusBar + 14;
        
        _windowNO2= no2;
    }
}
/**
 内部方法，用来产生可用的 ViewController，如果第一次使用。
 直接返回全新创建的对象，同时也预热一个相同类的对象，供下次使用。
 支持预热多个 ViewController，但是不易过多，容易引起内存紧张

 @param viewControllerClass UIViewController 子类
 @return UIViewControllerd 实例
 */
- (UIViewController *)getRendered:(Class)viewControllerClass cacheKey:(NSString *)key afterRender:(void (^)(UIViewController *))afterRender {
    [self setupWindowNO2];
    
    UIViewController *cacheVC = [self.renderedViewControllers objectForKey:key];
    if (cacheVC == nil) { // 下次使用缓存
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *nextVC = [viewControllerClass new];
            if (afterRender) {
                afterRender(nextVC);
            }
            // 解决 Unbalanced calls to begin/end appearance transitions for <UIViewController: 0xa98e050> 关键点
            // 1. 使用 UINavigationController  作为 no2 的 rootViewController
            // 2. 如果使用 UIViewController 作为 no2 的 rootViewController，始终有 Unbalanced calls 的错误
            // 虽然是编译器警告，实际上 Unbalanced calls  会影响被缓存的 vc， 当它被添加到当前活动的 UINavigation stack 时，它的生命周期是错误的
            // 所以这个警告必须解决。
            UINavigationController *nav = (UINavigationController *)self.windowNO2.rootViewController;
            [nav pushViewController:nextVC animated:NO];
            [self.renderedViewControllers setObject:nextVC forKey:key];
        });
        //
        return [viewControllerClass new];
    }  else { // 本次使用缓存，同时储备下次
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *fresh = [viewControllerClass new];
            if (afterRender) {
                afterRender(fresh);
            }
            // 在 setObject to renderedViewControllers 字典时，保证被渲染过
            [self.renderedViewControllers setObject:fresh forKey:key];
            // 必须是先设置 no2 的新 rootViewController，之后再复用从缓存中拿到的 viewControllerClass。否则会奔溃
            UINavigationController *nav = (UINavigationController *)self.windowNO2.rootViewController;
            // NOTE: 相同的 ViewControllerClass 只能缓存一个。
            NSMutableArray *newStacks = [NSMutableArray arrayWithCapacity:3];
            
            [nav.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj != cacheVC) {
                    [newStacks addObject:obj];
                }
            }];
            [newStacks addObject:fresh];
            nav.viewControllers = newStacks;
        });
        
        return cacheVC;
    }
}

/**
 主方法。传入一个 UIViewController 的 class 对象，在调用的 block 中同步的返回一个预先被渲染的 ViewController

 @param viewControllerClass  必须是 UIViewController 的 Class 对象
 @param block 业务逻辑回调
 */
- (void)getRenderedViewController:(Class)viewControllerClass completion:(void (^)(UIViewController *vc))block{
    // CATransaction 为了避免一个 push 动画和另外一个 push 动画同时进行的问题。
    [CATransaction begin];
    UIViewController *vc1 = [self getRendered:viewControllerClass cacheKey:NSStringFromClass(viewControllerClass) afterRender:nil];
    
    // 这里包含一个陷阱—— 必须先渲染将要被 cached 的 ViewController，然后再执行真实的 block
    // 理想情况，应该是先执行 block，然后执行 cache ViewController，因为 block 更重要些。暂时没想到方法
    [CATransaction setCompletionBlock:^{
        block(vc1);
    }];
    [CATransaction commit];
}


- (void)getWebViewController:(Class)viewControllerClass preloadURL:(NSString *)url completion:(void (^)(AppHostViewController *vc))block{
    // CATransaction 为了避免一个 push 动画和另外一个 push 动画同时进行的问题。
    if (viewControllerClass != AppHostViewController.class && ![viewControllerClass isSubclassOfClass:AppHostViewController.class]) {
        AHLog(@"Error ClassName = %@", NSStringFromClass(viewControllerClass));
        block([viewControllerClass new]);
        return;
    }
    
    NSString *key = [NSStringFromClass(viewControllerClass) stringByAppendingString:url];
    AppHostViewController *cached = (AppHostViewController *)[self getRendered:viewControllerClass cacheKey:key afterRender:^(UIViewController *obj) {
        AppHostViewController *nextVC = (AppHostViewController *)obj;
        nextVC.url = url;
    }];
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        block(cached);
    }];
    [CATransaction commit];
}

- (void)dealMemoryWarnings:(id)notif
{
    NSLog(@"release memory pressure");
    [self.renderedViewControllers removeAllObjects];
}
@end
