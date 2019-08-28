//
//  AppInstalledHelper.h
//  ImageOptimAggregationForMac
//
//  Created by LiMingjie on 2019/8/28.
//  Copyright © 2019 LMJ. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppInstalledHelper : NSObject

+ (BOOL)isInstallAppOfBundleIdentifier:(NSString *)bundleId;

@end

NS_ASSUME_NONNULL_END
