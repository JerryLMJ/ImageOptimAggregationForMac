//
//  AppInstalledHelper.m
//  ImageOptimAggregationForMac
//
//  Created by LiMingjie on 2019/8/28.
//  Copyright © 2019 LMJ. All rights reserved.
//

#import "AppInstalledHelper.h"

@implementation AppInstalledHelper

+ (BOOL)isInstallAppOfBundleIdentifier:(NSString *)bundleId {
    CFArrayRef urlArrayRef = LSCopyApplicationURLsForBundleIdentifier((__bridge CFStringRef)bundleId, NULL);
    if(urlArrayRef != NULL && CFArrayGetCount(urlArrayRef) > 0) {
        return YES;
    } else {
        return NO;
    }
}

@end
