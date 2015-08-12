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
        if (LOG_MODEL) NSLog(@"[ModelManager] No wind speed unit, guessing the preferred unit to be: %@", windSpeedUnit);
        [Property setAsInteger:windSpeedUnit forKey:KEY_WIND_SPEED_UNIT];
    }

    if ([Property getAsInteger:KEY_DIRECTION_UNIT] == nil) {
        // this must be the first time, since there is no direction unit
        NSNumber* directionUnit = [NSNumber numberWithInt:0];
        if (LOG_MODEL) NSLog(@"[ModelManager] No direction unit, setting it to: %@", directionUnit);
        [Property setAsInteger:directionUnit forKey:KEY_DIRECTION_UNIT];
    }

    if ([Property getAsInteger:KEY_PRESSURE_UNIT] == nil) {
        [Property setAsInteger:@0 forKey:KEY_PRESSURE_UNIT];
    }

    if ([Property getAsInteger:KEY_TEMPERATURE_UNIT] == nil) {
        [Property setAsInteger:@0 forKey:KEY_TEMPERATURE_UNIT];
    }

    
    if ([Property getAsDouble:KEY_FREQUENCY_START] == nil) {
        // this must be the first time, since frequency start (and related properties) are not set
        [Property setAsDouble:[AlgorithmConstantsUtil getFrequencyStart:model osVersion:osVersion] forKey:KEY_FREQUENCY_START];
        [Property setAsDouble:[AlgorithmConstantsUtil getFrequencyFactor:model osVersion:osVersion] forKey:KEY_FREQUENCY_FACTOR];
        [Property setAsInteger:[AlgorithmConstantsUtil getFFTLength:model osVersion:osVersion] forKey:KEY_FFT_LENGTH];
        [Property setAsInteger:[AlgorithmConstantsUtil getFFTDataLength:model osVersion:osVersion] forKey:KEY_FFT_DATA_LENGTH];
        [Property setAsInteger:[AlgorithmConstantsUtil getAlgorithm:model osVersion:osVersion] forKey:KEY_ALGORITHM];
        if (LOG_MODEL) NSLog(@"[ModelManager] Setting algorithm parameters from local detection: algorithm=%@, frequencyStart=%@, frequencyFactor=%@, fftLength=%@, fftDataLength=%@", [Property getAsInteger:KEY_ALGORITHM], [Property getAsDouble:KEY_FREQUENCY_START], [Property getAsDouble:KEY_FREQUENCY_FACTOR], [Property getAsInteger:KEY_FFT_LENGTH], [Property getAsInteger:KEY_FFT_DATA_LENGTH]);
    }
    
    if ([Property getAsDouble:KEY_FFT_MAG_MIN] == nil) {
        [Property setAsDouble:[AlgorithmConstantsUtil getFFTMagMin:model osVersion:osVersion] forKey:KEY_FFT_MAG_MIN];
        if (LOG_MODEL) NSLog(@"[ModelManager] Setting algorithm parameter from local detection: fftMagMin=%@", [Property getAsDouble:KEY_FFT_MAG_MIN]);
    }

    if ([Property getAsDouble:KEY_ANALYTICS_GRID_DEGREE] == nil) {
        // this must be the first time, since there is no grid degree
        NSNumber* analyticsGridDegree = [NSNumber numberWithDouble:0.125];
        if (LOG_MODEL) NSLog(@"[ModelManager] No grid degree, defaulting to: %@", analyticsGridDegree);
        [Property setAsDouble:analyticsGridDegree forKey:KEY_ANALYTICS_GRID_DEGREE];
    }

    NSArray *hourOptions = [Property getAsFloatArray:KEY_HOUR_OPTIONS];
    if (hourOptions == nil || hourOptions.count == 0) {
        hourOptions = [NSArray arrayWithObjects:[NSNumber numberWithFloat:3.0f], [NSNumber numberWithFloat:6.0f], [NSNumber numberWithFloat:12.0f], [NSNumber numberWithFloat:24.0f], nil];
        if (LOG_MODEL) NSLog(@"[ModelManager] No hour options, defaulting to: (%@)", [hourOptions componentsJoinedByString:@","]);
        [Property setAsFloatArray:hourOptions forKey:KEY_HOUR_OPTIONS];
    }
    
    if ([Property getAsString:KEY_ENABLE_FACEBOOK_DISCLAIMER] == nil) {
        BOOL enableFacebookDisclaimer = (arc4random_uniform(2) == 1);
        if (LOG_MODEL) NSLog(@"[ModelManager] No Facebook disclaimer flag, randomly choosing: %@", enableFacebookDisclaimer ? @"YES" : @"NO");
        [Property setAsBoolean:enableFacebookDisclaimer forKey:KEY_ENABLE_FACEBOOK_DISCLAIMER];
    }

    // make sure nothing else get executed until changes are written to the database
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

+ (NSString *)getModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *sDeviceModel = [NSString stringWithCString:systemInfo.machine
                                                encoding:NSUTF8StringEncoding];
    
    return sDeviceModel;
    
    // NOT in use anymore;
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

+ (BOOL)isIPhone4 {
    return [[ModelManager getModel] hasPrefix:@"iPhone3"];
}

@end
