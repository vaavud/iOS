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

@implementation ModelManager

SHARED_INSTANCE

- (id) init {
    self = [super init];
    
    if (self) {
    }
    
    return self;
}

- (void) initializeModel {
    NSString* deviceUuid = [Property getAsString:KEY_DEVICE_UUID];
    if (!deviceUuid || deviceUuid == nil) {
        NSLog(@"[ModelManager] First run ever, initializing model");
        
        deviceUuid = [UUIDUtil generateUUID];
        [Property setAsString:deviceUuid forKey:KEY_DEVICE_UUID];
    }

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *appBuild = [infoDictionary objectForKey:@"CFBundleVersion"];
    NSString *os = [[UIDevice currentDevice] systemName];
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    NSString *model = [[UIDevice currentDevice] model];
    NSString *country = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
	NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];

    NSLog(@"[ModelManager] app:%@, appVersion:%@, appBuild:%@, os:%@, osVersion:%@, model:%@, deviceUuid:%@, countryCode:%@, language:%@", app, appVersion, appBuild, os, osVersion, model, deviceUuid, country, language);
    

    // detect changes and optionally save
    
    if ([app compare:[Property getAsString:KEY_APP]] != NSOrderedSame) {
        [Property setAsString:app forKey:KEY_APP];
    }
    if ([appVersion compare:[Property getAsString:KEY_APP_VERSION]] != NSOrderedSame) {
        [Property setAsString:appVersion forKey:KEY_APP_VERSION];
    }
    if ([appBuild compare:[Property getAsString:KEY_APP_BUILD]] != NSOrderedSame) {
        [Property setAsString:appBuild forKey:KEY_APP_BUILD];
    }
    if ([os compare:[Property getAsString:KEY_OS]] != NSOrderedSame) {
        [Property setAsString:os forKey:KEY_OS];
    }
    if ([osVersion compare:[Property getAsString:KEY_OS_VERSION]] != NSOrderedSame) {
        [Property setAsString:osVersion forKey:KEY_OS_VERSION];
    }
    if ([model compare:[Property getAsString:KEY_MODEL]] != NSOrderedSame) {
        [Property setAsString:model forKey:KEY_MODEL];
    }
    if ([country compare:[Property getAsString:KEY_COUNTRY]] != NSOrderedSame) {
        [Property setAsString:country forKey:KEY_COUNTRY];
    }
    if ([language compare:[Property getAsString:KEY_LANGUAGE]] != NSOrderedSame) {
        [Property setAsString:language forKey:KEY_LANGUAGE];
    }

    if ([Property getAsInteger:KEY_WIND_SPEED_UNIT] == nil) {
        // this must be the first time, since there is no wind speed unit
        NSNumber* windSpeedUnit = [NSNumber numberWithInt:[UnitUtil windSpeedUnitForCountry:country]];
        NSLog(@"[ModelManager] No wind speed unit, guessing the preferred unit to be: %@", windSpeedUnit);
        [Property setAsInteger:windSpeedUnit forKey:KEY_WIND_SPEED_UNIT];
    }
    
    // make sure nothing else get executed until changes are written to the database
    [[NSManagedObjectContext defaultContext] saveToPersistentStoreAndWait];
}

@end
