//
//  AHPrefechLoader.h
//  AppHost
//
//  Created by hite on 2021/3/12.
//  Copyright © 2021 liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHPrefetchLoaderProtocol.h"
#import "AHLogProviderProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AHPrefetchfigInterfacesModel : NSObject

@property (nonatomic, strong) NSString *api;

@property (nonatomic, strong) NSString *method;

@end

@interface AHPrefetchfigItemModel : NSObject

@property (nonatomic, strong) NSString *url;

@property (nonatomic, strong) NSArray<AHPrefetchfigInterfacesModel *> *interfaces;

@end


@interface AHPrefechLoader : NSObject<AHPrefetchLoaderProtocol>

@property (nonatomic, strong) NSString *prefetchUrl;

- (void)setLogger:(id<AHLogProviderProtocol>)logger;

@end

NS_ASSUME_NONNULL_END
