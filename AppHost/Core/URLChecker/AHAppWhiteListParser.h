//
//  MKAppWhiteListParser.h

//
//  Created by hite on 4/21/16.
//  Copyright © 2016 smilly.co All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AHAppWhiteListParser : NSObject
+ (instancetype)sharedManager;
/**
 *  读取一个文件，解析为一个规则的对象，返回
 *
 *  @param fileContent   文件内容
 *  @return 包括key，value的对象，value是域名字符串的数组。
 */
- (NSDictionary *)parserFileContent:(NSString *)fileContent;

@end
