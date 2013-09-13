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

@interface ModelManager() {

}

+ (NSString*) getModel;

@end


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
    NSString *model = [ModelManager getModel];
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

+ (NSString*) getModel
{
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *sDeviceModel = [NSString stringWithCString:systemInfo.machine
                                                encoding:NSUTF8StringEncoding];
    
    // http://theiphonewiki.com/wiki/Models  // Maria would like to update tge list
    
    if ([sDeviceModel isEqual:@"i386"])      return @"Simulator";         // iPhone Simulator
    if ([sDeviceModel isEqual:@"iPhone1,1"]) return @"iPhone2G";          // iPhone 2G
    if ([sDeviceModel isEqual:@"iPhone1,2"]) return @"iPhone3G";          // iPhone 3G
    if ([sDeviceModel isEqual:@"iPhone2,1"]) return @"iPhone3GS";         // iPhone 3GS
    if ([sDeviceModel isEqual:@"iPhone3,1"]) return @"iPhone4GSM";        // iPhone 4 (GSM)
    if ([sDeviceModel isEqual:@"iPhone3,2"]) return @"iPhone4GSMRevA";    // iPhone 4 (GMS Rev A)
    if ([sDeviceModel isEqual:@"iPhone3,3"]) return @"iPhone4GSM+CDMA";   // iPhone 4 (GSM + CDMA)
    if ([sDeviceModel isEqual:@"iPhone4,1"]) return @"iPhone4S";          // iPhone 4S
    if ([sDeviceModel isEqual:@"iPhone5,1"]) return @"iPhone5GSM";        // iPhone 5 (GSM)
    if ([sDeviceModel isEqual:@"iPhone5,2"]) return @"iPhone5GSM+CDMA";   // iPhone 5 (GSM + CDMA)
    if ([sDeviceModel isEqual:@"iPod1,1"])   return @"iPod1stGen";        // iPod Touch 1G
    if ([sDeviceModel isEqual:@"iPod2,1"])   return @"iPod2ndGen";        // iPod Touch 2G
    if ([sDeviceModel isEqual:@"iPod3,1"])   return @"iPod3rdGen";        // iPod Touch 3G
    if ([sDeviceModel isEqual:@"iPod4,1"])   return @"iPod4thGen";        // iPod Touch 4G
    if ([sDeviceModel isEqual:@"iPod5,1"])   return @"iPod5thGen";        // iPod Touch 5G
    if ([sDeviceModel isEqual:@"iPad1,1"])   return @"iPadWiFi";          // iPad Wifi
    if ([sDeviceModel isEqual:@"iPad1,2"])   return @"iPad3G";            // iPad 3G
    if ([sDeviceModel isEqual:@"iPad2,1"])   return @"iPad2WiFi";         // iPad 2 (WiFi)
    if ([sDeviceModel isEqual:@"iPad2,2"])   return @"iPad2GSM";          // iPad 2 (GSM)
    if ([sDeviceModel isEqual:@"iPad2,3"])   return @"iPad2CDMA";         // iPad 2 (CDMA)
    if ([sDeviceModel isEqual:@"iPad2,4"])   return @"iPad2WiFiRevA";     // iPad 2 (WiFi Rev A)
    if ([sDeviceModel isEqual:@"iPad3,1"])   return @"ipad3WiFi";         // iPad 3 (WiFi)
    if ([sDeviceModel isEqual:@"iPad3,2"])   return @"ipad3GSM";          // iPad 3 (GMS)
    if ([sDeviceModel isEqual:@"iPad3,3"])   return @"ipad3CDMA";         // iPad 3 (CDMA)
    if ([sDeviceModel isEqual:@"iPad3,4"])   return @"iPad4WiFi";         // iPad 4 (WiFi)
    if ([sDeviceModel isEqual:@"iPad3,5"])   return @"iPad4GSM";          // iPad 4 (GSM)
    if ([sDeviceModel isEqual:@"iPad3,6"])   return @"iPad4GSM+CDMA";     // iPad 4 (GSM + CDMA)
    if ([sDeviceModel isEqual:@"iPad2,5"])   return @"iPadMini1GWiFi";    // iPad Mini 1G (WiFi)
    if ([sDeviceModel isEqual:@"iPad2,6"])   return @"iPadMini1GGSM";     // iPad Mini 1G (GSM)
    if ([sDeviceModel isEqual:@"iPad2,7"])   return @"iPadMini1GGSM+CDMA";// iPad Mini 1G (GSM + CDMA)
    
    
    // if no equal is found
    return sDeviceModel;
    
}

@end
