//
//  AHHTTPSchemeTaskDelegate.m
//  AppHost
//
//  Created by hite on 2021/3/11.
//  Copyright © 2021 liang. All rights reserved.
//

#import "AHHTTPSchemeTaskDelegate.h"

@implementation AHHTTPSchemeTaskDelegate

- (void)webView:(WKWebView *)webView startURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask
{
    NSURLRequest *request = urlSchemeTask.request;
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (data == nil) {
                    NSError *err = [[NSError alloc] initWithDomain:@"自定义的资源无法解析" code:-4003 userInfo:nil];
                    [urlSchemeTask didFailWithError:err];
                } else {
                    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:urlSchemeTask.request.URL MIMEType:@"text/html" expectedContentLength:data.length textEncodingName:nil];
                    [urlSchemeTask didReceiveResponse:response];
                    [urlSchemeTask didReceiveData:data];
                    [urlSchemeTask didFinish];
                }
        }] resume];
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    //
    AHLog(@"%@", NSStringFromSelector(_cmd));
}

@end
