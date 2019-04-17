//
//  MKURLChecker.m

//  Created by hite on 4/22/16.
//  Copyright © 2016 smilly.co. All rights reserved.
//

#import "AHURLChecker.h"
#import "AHAppWhiteListParser.h"

@implementation AHURLChecker

static AHURLChecker *_sharedManager = nil;
static NSDictionary *_authorizedTable = nil;
+ (instancetype)sharedManager
{

    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
        // 默认数据
        NSString *path = [[NSBundle mainBundle] pathForResource:@"app-access" ofType:@"txt"];
        NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        _authorizedTable = [[AHAppWhiteListParser sharedManager] parserFileContent:fileContents];
    });

    return _sharedManager;
}

- (BOOL)checkURL:(NSURL *)url forAuthorizationType:(AHAuthorizationType)authType
{
#ifdef DEBUG
    return YES;
#else
    if (url == nil) {
        return NO;
    }
    // 本地测试地址。
    NSString *directory = NSHomeDirectory();                                  // user文件根目录 /var/mobile/..
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];                // /var/containers/
    NSString *bundleURL = [[[NSBundle mainBundle] bundleURL] absoluteString]; // file:///
    NSString *tempDir = NSTemporaryDirectory();                               //在真机上/private/..
    if ([url.absoluteString hasPrefix:directory] || [url.absoluteString hasPrefix:bundlePath] || [url.absoluteString hasPrefix:bundleURL] ||
        [url.absoluteString hasPrefix:tempDir]) {
        return YES;
    }

    NSString *key = nil;
    if (authType == AHAuthorizationTypeSchema) {
        key = @"schema-open-url";
    }
    else if (authType == AHAuthorizationTypeAppHost) {
        key = @"apphost";
    }
    if (key) {
        NSArray *rules = [_authorizedTable objectForKey:key];
        if ([rules count] == 0) {
            return YES; // 白名单为空，放行
        }
        BOOL pass = NO;
        
        for (NSInteger i = 0, l = [rules count]; i < l; i++) {
            NSString *rule = [rules objectAtIndex:i];
            // 将.号处理为\.如mail.163.com => mail\\.163\\.com;
            rule = [rule stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
            // 将*号处理为 [a-z0-9]+,
            rule = [rule stringByReplacingOccurrencesOfString:@"*" withString:@"[\\w\\d-_]+"];
            // 精确匹配. 开始和结尾
            rule = [NSString stringWithFormat:@"^%@$", rule];

            NSError *regexError = nil;
            NSRegularExpression *regex = [NSRegularExpression
                regularExpressionWithPattern:rule
                                     options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                       error:&regexError];

            if (regexError) {
                NSLog(@"Regex creation failed with error: %@", [regexError description]);
                continue;
            }
            // 使用host
            NSString *host = [url host];
            NSArray *matches = [regex matchesInString:host options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0, host.length)];
            if ([matches count] > 0) {
                pass = YES;
                break;
            }
        }
        return pass;
    }
    else {
        return YES; // 不在授权类型里的，默认返回通过。
    }
#endif
}


@end
