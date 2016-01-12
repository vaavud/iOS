//
//  ModelManager.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 09/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "ModelManager.h"
#import "SharedSingleton.h"
#import "Property+Util.h"
#import "UUIDUtil.h"
#import "UnitUtil.h"
#import "sys/utsname.h"
#import "MeasurementSession.h"
#import "MeasurementPoint.h"
#import "AlgorithmConstantsUtil.h"

@interface ModelManager()

+ (NSString *)getModel;

@end


@implementation ModelManager

SHARED_INSTANCE

- (void)initializeModel {
    NSString *deviceUuid = [Property getAsString:KEY_DEVICE_UUID];
    if (!deviceUuid || deviceUuid == nil) {
        if (LOG_MODEL) NSLog(@"[ModelManager] First run ever, initializing model");
        
        deviceUuid = [UUIDUtil generateUUID];
        [Property setAsString:deviceUuid forKey:KEY_DEVICE_UUID];
        [Property setAsDate:[NSDate date] forKey:KEY_CREATION_TIME];
    }
    
    
    let mobileVersion =  UIDevice.currentDevice().systemVersion
    let appVersion = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String
    let model = UIDevice.currentDevice().name
    let vendor = "Apple"
    
    let deviceObj = Device(appVersion: appVersion, model: model, vendor: vendor, osVersion: mobileVersion, uid: uid)
    

    

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *appBuild = [infoDictionary objectForKey:@"CFBundleVersion"];
    NSString *os = [[UIDevice currentDevice] systemName];

    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    NSString *model = [ModelManager getModel];
    NSString *country = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
	NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];

    if (LOG_MODEL) NSLog(@"[ModelManager] app:%@, appVersion:%@, appBuild:%@, os:%@, osVersion:%@, model:%@, deviceUuid:%@, countryCode:%@, language:%@", app, appVersion, appBuild, os, osVersion, model, deviceUuid, country, language);

    // detect changes and optionally save
    
//    if ([app compare:[Property getAsString:KEY_APP]] != NSOrderedSame) {
//        [Property setAsString:app forKey:KEY_APP];
//    }
//    if ([appVersion compare:[Property getAsString:KEY_APP_VERSION]] != NSOrderedSame) {
//        [Property setAsString:appVersion forKey:KEY_APP_VERSION];
//    }
//    if ([appBuild compare:[Property getAsString:KEY_APP_BUILD]] != NSOrderedSame) {
//        [Property setAsString:appBuild forKey:KEY_APP_BUILD];
//    }
//    if ([os compare:[Property getAsString:KEY_OS]] != NSOrderedSame) {
//        [Property setAsString:os forKey:KEY_OS];
//    }
//    if ([osVersion compare:[Property getAsString:KEY_OS_VERSION]] != NSOrderedSame) {
//        [Property setAsString:osVersion forKey:KEY_OS_VERSION];
//    }
//    if ([model compare:[Property getAsString:KEY_MODEL]] != NSOrderedSame) {
//        [Property setAsString:model forKey:KEY_MODEL];
//    }
//    if ([country compare:[Property getAsString:KEY_COUNTRY]] != NSOrderedSame) {
//        [Property setAsString:country forKey:KEY_COUNTRY];
//    }
//    if ([language compare:[Property getAsString:KEY_LANGUAGE]] != NSOrderedSame) {
//        [Property setAsString:language forKey:KEY_LANGUAGE];
//    }
//    
//    if ([Property getAsDouble:KEY_ANALYTICS_GRID_DEGREE] == nil) {
//        // this must be the first time, since there is no grid degree
//        NSNumber* analyticsGridDegree = [NSNumber numberWithDouble:0.125];
//        if (LOG_MODEL) NSLog(@"[ModelManager] No grid degree, defaulting to: %@", analyticsGridDegree);
//        [Property setAsDouble:analyticsGridDegree forKey:KEY_ANALYTICS_GRID_DEGREE];
//    }

//    NSArray *hourOptions = [Property getAsFloatArray:KEY_HOUR_OPTIONS];
//    if (hourOptions == nil || hourOptions.count == 0) {
//        hourOptions = [NSArray arrayWithObjects:[NSNumber numberWithFloat:3.0f], [NSNumber numberWithFloat:6.0f], [NSNumber numberWithFloat:12.0f], [NSNumber numberWithFloat:24.0f], nil];
//        if (LOG_MODEL) NSLog(@"[ModelManager] No hour options, defaulting to: (%@)", [hourOptions componentsJoinedByString:@","]);
//        [Property setAsFloatArray:hourOptions forKey:KEY_HOUR_OPTIONS];
//    }
}

+ (NSString *)getModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *sDeviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    return sDeviceModel;
}

+ (BOOL)isIPhone4 {
    return [[ModelManager getModel] hasPrefix:@"iPhone3"];
}

@end
