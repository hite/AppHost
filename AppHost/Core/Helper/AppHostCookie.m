//
//  MKAppHostCookie.m

//
//  Created by liang on 06/01/2018.
//  Copyright © 2018 smilly.co All rights reserved.
//

#import "AppHostCookie.h"
#import "AppHostEnum.h"

@implementation AppHostCookie

+ (NSMutableArray<NSString *> *)cookieJavaScriptArray
{
    NSMutableArray<NSString *> *cookieStrings = [[NSMutableArray alloc] init];
    //取出cookie
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookieStorage.cookies) {
        //
        NSString *excuteJSString = [NSString stringWithFormat:@"%@=%@;", cookie.name, cookie.value];
        if (cookie.domain.length > 0) {
            excuteJSString = [excuteJSString stringByAppendingFormat:@"domain=%@;", cookie.domain];
        }
        if (cookie.path.length > 0) {
            excuteJSString = [excuteJSString stringByAppendingFormat:@"path=%@;", cookie.path];
        }
        if (cookie.expiresDate != nil) {
            excuteJSString = [excuteJSString stringByAppendingFormat:@"expires=%@;", cookie.expiresDate];
        }
        if (cookie.secure) {
            excuteJSString = [excuteJSString stringByAppendingString:@"secure=true"];
        }
        
        [cookieStrings addObject:excuteJSString];
        AHLog(@"cookie to be set = %@", excuteJSString);
    }

    return cookieStrings;
}

static WKProcessPool *_sharedManager = nil;
// 当从未登录到登录时，这个状态需要置为 No
static BOOL kLoginCookieHasBeenSynced = NO;

+ (WKProcessPool *)sharedPoolManager
{

    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [[WKProcessPool alloc] init];
        // 监听 urs 登出的事件。
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogout:) name:kAHLogoutNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUserLoginSucss:) name:kAHLoginSuccessNotification object:nil];
    });
    
    return _sharedManager;
}

+ (void)didLogout:(id)notif
{
    // 清空旧的 WKProcessPool
    AHLog(@"didLogout, old pool is destoryed");
    _sharedManager = [[WKProcessPool alloc] init];
}

#pragma mark - cookie sync part

+ (void)didUserLoginSucss:(id)notif
{
    kLoginCookieHasBeenSynced = NO;
}

+ (void)setLoginCookieHasBeenSynced:(BOOL)synced
{
    kLoginCookieHasBeenSynced = synced;
}

+ (BOOL)loginCookieHasBeenSynced
{
    return kLoginCookieHasBeenSynced;
}
@end
