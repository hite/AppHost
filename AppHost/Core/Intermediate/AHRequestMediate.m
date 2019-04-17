//
//  AHRequestMediate.m
//  AppHost
//
//  Created by liang on 2019/3/22.
//  Copyright © 2019 liang. All rights reserved.
//

#import "AHRequestMediate.h"
#import "AppHostProtocol.h"
#import "HTMLParser.h"
#import "AHUtil.h"
#import "AppHostEnum.h"

static NSString *kFilePrefix = @"file://";
@implementation AHRequestMediate

+ (int)interMediateFile:(NSString *)fileName inDirectory:(NSURL *)directory domain:(NSString *)domain output:(NSString *_Nonnull*_Nonnull)output
{
    NSString *version= [UIDevice currentDevice].systemVersion;
    // 当 domain 是 https 域的时候，会因为 CSP 阻止自定义 wkurlschemehandler 触发加载
    if(version.doubleValue >= 11.0 && [domain hasPrefix:@"http://"]) {
        return [self _above_iOS11_interMediateFile:fileName inDirectory:directory output:output];
    } else {
        return [self _below_iOS11_interMediateFile:fileName inDirectory:directory output:output];
    }
}

+ (int)_above_iOS11_interMediateFile:(NSString *)fileName inDirectory:(NSURL *)directory output:(NSString **)output
{
    int ext = 0;
    // 实现方式是；将 js，css，图片全部都按照自定义 WKURLSchemeTask 来处理，好处是可以级联处理
    //TODO html 的原文，可能是不规范的 tag，如单引号的 script, <script src='a.b.js'/> 但是从 html parse 得到的是规范的 html tag 标签，是双引号，所以需要做一次转换
    NSError *error;
    NSStringEncoding encoding = NSUTF8StringEncoding;
    __block NSString *htmlContent = [NSString stringWithContentsOfURL:[directory URLByAppendingPathComponent:fileName] usedEncoding:&encoding error:&error];
    
    if( htmlContent.length == 0){
        return -1;
    }
    // 先从 HTML 里拿到对应的字符串
    // 不用正则来替换文件名和内容，而是使用先计算要替换的位置和替换内容，最后一起替换
    HTMLParser *parser = [[HTMLParser alloc] initWithString:htmlContent error:&error];
    
    if (error) {
        NSLog(@"Error: %@", error);
        return -1;
    }
    
    NSMutableDictionary *replacements = [NSMutableDictionary dictionaryWithCapacity:10];
    
    // 处理 style 引入的文件
    NSError *err = nil;
    HTMLNode *bodyNode = [parser html];
    NSArray *inputNodes = [bodyNode findChildTags:@"link"];
    for (HTMLNode *inputNode in inputNodes) {
        NSString *linkedCss = [inputNode getAttributeNamed:@"href"];
        if ([AHUtil isNetworkUrl:linkedCss]) {
            continue;
        }
        
        NSString *originalStyle = inputNode.rawContents;
        AHLog(@"style src = %@, rawContents = %@", linkedCss, originalStyle);
        if (originalStyle.length > 0) {
            NSString *path = [[[directory URLByAppendingPathComponent:linkedCss] absoluteString] stringByReplacingOccurrencesOfString:kFilePrefix withString:AppHostURLStyleServer];
            NSString *styleTxt = [NSString stringWithFormat:@"<link rel=\"stylesheet\" href=\"%@\">", path];
            [replacements setObject:styleTxt forKey:originalStyle];
        } else {
            ext = -2;
            AHLog(@"Replace linked css error, originalStyle = %@", originalStyle);
        }
    }
    
    // 处理 script
    NSArray *spanNodes = [bodyNode findChildTags:@"script"];
    for (HTMLNode *spanNode in spanNodes) {
        NSString *linkedScript = [spanNode getAttributeNamed:@"src"];
        if ([AHUtil isNetworkUrl:linkedScript]) {
            continue;
        }
        if (linkedScript.length > 0) {
            NSString *originalScript = spanNode.rawContents;
            AHLog(@"script src = %@, rawContents = %@", linkedScript, originalScript);
            if (originalScript.length > 0) {
                NSString *path = [[[directory URLByAppendingPathComponent:linkedScript] absoluteString] stringByReplacingOccurrencesOfString:kFilePrefix withString:AppHostURLScriptServer];
                NSString *scriptTxt = [NSString stringWithFormat:@"<script type=\"text/javascript\" src=\"%@\"></script>", path];
                [replacements setObject:scriptTxt forKey:originalScript];
            } else {
                ext = -3;
                AHLog(@"Replace linked script originalScript = %@", originalScript);
            }
        }
    }
    
    // 处理图片, 只处理 img 标签。
    NSArray *imgNode = [bodyNode findChildTags:@"img"];
    for (HTMLNode *spanNode in imgNode) {
        NSString *imgSrc = [spanNode getAttributeNamed:@"src"];
        if ([AHUtil isNetworkUrl:imgSrc]) {
            continue;
        }
        if (imgSrc.length > 0) {
            NSString *originalSrc = spanNode.rawContents;
            AHLog(@"image src = %@, rawContents = %@", imgSrc,originalSrc);
            if (imgSrc.length > 0) {
                NSError *error = nil;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"src=['\"](.)+['\"]" options:NSRegularExpressionCaseInsensitive error:&error];
                NSString *path = [[[directory URLByAppendingPathComponent:imgSrc] absoluteString] stringByReplacingOccurrencesOfString:kFilePrefix withString:AppHostURLImageServer];
                NSString *modifiedString = [regex stringByReplacingMatchesInString:originalSrc options:0 range:NSMakeRange(0, [originalSrc length]) withTemplate:[NSString stringWithFormat:@"src=\"%@\"", path]];
                
                [replacements setObject:modifiedString forKey:originalSrc];
            } else {
                ext = -4;
                AHLog(@"Replace linked script originalScript = %@", imgSrc);
            }
        }
    }
    
    // 遍历 replacements，执行替换动作
    [replacements enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        if (![htmlContent containsString:key]) {
            // 如果遇到对写 htmlContent 不和规范，如在末位加 /,<link href="//www.cnbeta.com/css/style.css" rel="stylesheet"/>
            // 这样的模式，需要把 key 处理下，加上 / 符号。然后再替换
            key = [key stringByReplacingOccurrencesOfString:@">" withString:@"/>"];
        }
        htmlContent = [htmlContent stringByReplacingOccurrencesOfString:key withString:obj];
    }];
    //
    *output = htmlContent;
    return err == nil? 0: -1;
}

+ (int)_below_iOS11_interMediateFile:(NSString *)fileName inDirectory:(NSURL *)directory output:(NSString **)output
{
    //TODO html 的原文，可能是不规范的 tag，如单引号的 script, <script src='a.b.js'/> 但是从 html parse 得到的是规范的 html tag 标签，是双引号，所以需要做一次转换
    int ext = 0;
    // 实现方式是；将这些文件合并为新的 HTML，css 和 js 都作为内联的 script 和 style；
    // 先把 filename 读出来，作为一个 ast，分析到相对 css、js，填充到新的 HTML 里
    NSError *error;
    NSStringEncoding encoding = NSUTF8StringEncoding;
    __block NSString *htmlContent = [NSString stringWithContentsOfURL:[directory URLByAppendingPathComponent:fileName] usedEncoding:&encoding error:&error];
    if( htmlContent.length == 0){
        return -1;
    }
    // 先从 HTML 里拿到对应的字符串
    // 不用正则来替换文件名和内容，而是使用先计算要替换的位置和替换内容，最后一起替换

    HTMLParser *parser = [[HTMLParser alloc] initWithString:htmlContent error:&error];
    
    if (error) {
        NSLog(@"Error: %@", error);
        return -1;
    }
    
    NSMutableDictionary *replacements = [NSMutableDictionary dictionaryWithCapacity:10];
    
    // 处理 style 引入的文件
    NSError *err = nil;
    HTMLNode *bodyNode = [parser html];
    NSArray *inputNodes = [bodyNode findChildTags:@"link"];
    for (HTMLNode *inputNode in inputNodes) {
        NSString *linkedCss = [inputNode getAttributeNamed:@"href"];
        if ([AHUtil isNetworkUrl:linkedCss]) {
            continue;
        }
        
        NSString *content = [NSString stringWithContentsOfURL:[directory URLByAppendingPathComponent:linkedCss] usedEncoding:&encoding error:&err];
        
        NSString *originalStyle = inputNode.rawContents;
        AHLog(@"style src = %@, rawContents = %@", linkedCss, originalStyle);
        if (err == nil && originalStyle.length > 0 && content.length > 0) {
            NSString *styleTxt = [NSString stringWithFormat:@"<style type='text/css'>%@</style>", content];
            [replacements setObject:styleTxt forKey:originalStyle];
        } else {
            ext = -2;
            AHLog(@"Replace linked css error = %@ , originalStyle = %@, content = %@", err, originalStyle, content);
        }
    }
    
    // 处理 script
    NSArray *spanNodes = [bodyNode findChildTags:@"script"];
    for (HTMLNode *spanNode in spanNodes) {
        NSString *linkedScript = [spanNode getAttributeNamed:@"src"];
        if ([AHUtil isNetworkUrl:linkedScript]) {
            continue;
        }
        
        if (linkedScript.length > 0) {
            NSString *content = [NSString stringWithContentsOfURL:[directory URLByAppendingPathComponent:linkedScript] usedEncoding:&encoding error:&err];
            
            NSString *originalScript = spanNode.rawContents;
            AHLog(@"script src = %@, rawContents = %@", linkedScript, originalScript);
            if (err == nil && originalScript.length > 0 && content.length > 0) {
                NSString *scriptTxt = [NSString stringWithFormat:@"<script type='text/javascript'>%@</script>", content];
                [replacements setObject:scriptTxt forKey:originalScript];
            } else {
                ext = -3;
                AHLog(@"Replace linked script error = %@, originalScript = %@, content = %@", err, originalScript, content);
            }
        }
    }
    
    // 处理图片, 将图片实现为 base64字符串, 只处理 img 标签。
    NSArray *imgNode = [bodyNode findChildTags:@"img"];
    for (HTMLNode *spanNode in imgNode) {
        NSString *imgSrc = [spanNode getAttributeNamed:@"src"];
        if ([AHUtil isNetworkUrl:imgSrc]) {
            continue;
        }
        if (imgSrc.length > 0) {
            NSString *originalSrc = spanNode.rawContents;
            AHLog(@"image src = %@, rawContents = %@", imgSrc,originalSrc);
            if (imgSrc.length > 0) {
                NSURL *imgURL = [directory URLByAppendingPathComponent:imgSrc];
                // 把文件转成 base64
                NSData *imageData = [NSData dataWithContentsOfURL:imgURL];
                NSString *encodedImageStr = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                
                NSError *error = nil;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"src=['\"](.)+['\"]" options:NSRegularExpressionCaseInsensitive error:&error];
                
                NSString *imageType = @"image/jpeg";
                if ([imgSrc hasSuffix:@".png"]){
                    imageType = @"image/png";
                }
                
                NSString *modifiedString = [regex stringByReplacingMatchesInString:originalSrc options:0 range:NSMakeRange(0, [originalSrc length]) withTemplate:[NSString stringWithFormat:@"src='data:%@;base64,%@'", imageType,encodedImageStr]];
                
                [replacements setObject:modifiedString forKey:originalSrc];
            } else {
                ext = -4;
                AHLog(@"Replace linked script originalScript = %@", imgSrc);
            }
        }
    }
    // 遍历 replacements，执行替换动作
    [replacements enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        if (![htmlContent containsString:key]) {
            // 如果遇到对写 htmlContent 不和规范，如在末位加 /,<link href="//www.cnbeta.com/css/style.css" rel="stylesheet"/>
            // 这样的模式，需要把 key 处理下，加上 / 符号。然后再替换
            key = [key stringByReplacingOccurrencesOfString:@">" withString:@"/>"];
        }
        htmlContent = [htmlContent stringByReplacingOccurrencesOfString:key withString:obj];
    }];
    //
    *output = htmlContent;
    return err == nil? 0: -1;
}
@end
