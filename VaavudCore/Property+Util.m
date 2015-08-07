//
//  Property+Util.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 01/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "Property+Util.h"
#import "UnitUtil.h"
#import "MeasurementSession+Util.h"

NSString * const KEY_CREATION_TIME = @"creationTime";
NSString * const KEY_DEVICE_UUID = @"deviceUuid";
NSString * const KEY_AUTH_TOKEN = @"authToken";
NSString * const KEY_APP = @"app";
NSString * const KEY_APP_VERSION = @"appVersion";
NSString * const KEY_APP_BUILD = @"appBuild";
NSString * const KEY_OS = @"os";
NSString * const KEY_OS_VERSION = @"osVersion";
NSString * const KEY_MODEL = @"model";
NSString * const KEY_COUNTRY = @"country";
NSString * const KEY_LANGUAGE = @"language";
NSString * const KEY_WIND_SPEED_UNIT = @"windSpeedUnit";
NSString * const KEY_DIRECTION_UNIT = @"directionUnit";
NSString * const KEY_MAP_HOURS = @"mapHours";
NSString * const KEY_HAS_PROMPTED_FOR_LOCATION = @"hasPromptedForLocation";
NSString * const KEY_FREQUENCY_START = @"frequencyStart";
NSString * const KEY_FREQUENCY_FACTOR = @"frequencyFactor";
NSString * const KEY_FFT_LENGTH = @"fftLength";
NSString * const KEY_FFT_DATA_LENGTH = @"fftDataLength";
NSString * const KEY_FFT_MAG_MIN = @"fftMagMin";
NSString * const KEY_ALGORITHM = @"algorithm";
NSString * const KEY_ANALYTICS_GRID_DEGREE = @"analyticsGridDegree";
NSString * const KEY_HOUR_OPTIONS = @"hourOptions";
NSString * const KEY_ENABLE_MIXPANEL = @"enableMixPanel";
NSString * const KEY_ENABLE_MIXPANEL_PEOPLE = @"enableMixPanelPeople";
NSString * const KEY_ENABLE_FACEBOOK_DISCLAIMER = @"enableFacebookDisclaimer";
NSString * const KEY_ENABLE_SHARE_DIALOG = @"enableFacebookShareDialog";
NSString * const KEY_HAS_SEEN_INTRO_FLOW = @"hasSeenIntroFlow";
NSString * const KEY_MAP_GUIDE_MARKER_SHOWN = @"mapGuideMarkerShown";
NSString * const KEY_MAP_GUIDE_TIME_INTERVAL_SHOWN = @"mapGuideTimeIntervalShown";
NSString * const KEY_MAP_GUIDE_ZOOM_SHOWN = @"mapGuideZoomShown";
NSString * const KEY_SLEIPNIR_CLIP_SIDE_SCREEN = @"sleipnirClipSideScreen";

// User-related properties
NSString * const KEY_EMAIL = @"email";
NSString * const KEY_FACEBOOK_USER_ID = @"facebookUserId";
NSString * const KEY_FACEBOOK_ACCESS_TOKEN = @"facebookAccessToken";
NSString * const KEY_USER_ID = @"userId";
NSString * const KEY_FIRST_NAME = @"firstName";
NSString * const KEY_LAST_NAME = @"lastName";
NSString * const KEY_AUTHENTICATION_STATE = @"authenticationState";
NSString * const KEY_USER_HAS_WIND_METER = @"userHasWindMeter";

// Agri-related properties
NSString * const KEY_AGRI_VALID_SUBSCRIPTION = @"agriValidSubscription";
NSString * const KEY_AGRI_DEFAULT_REDUCING_EQUIPMENT = @"agriDefaultReducingEquipment";
NSString * const KEY_AGRI_DEFAULT_DOSE = @"agriDefaultDose";
NSString * const KEY_AGRI_DEFAULT_BOOM_HEIGHT = @"agriDefaultBoomHeight";
NSString * const KEY_AGRI_DEFAULT_SPRAY_QUALITY = @"agriDefaultSprayQuality";

// This is new
NSString * const KEY_AGRI_TEST_MODE = @"testMode";
NSString * const KEY_HAS_SEEN_UPGRADE_FLOW = @"hasSeenUpgradeFlow";

NSString * const KEY_TEMPERATURE_UNIT = @"temperatureUnit";
NSString * const KEY_PRESSURE_UNIT = @"pressureUnit";

NSString * const KEY_UNIT_CHANGED = @"unitChanged";

NSString * const KEY_LOCATION_HAS_ASKED = @"hasAskedForLocationAccess";
NSString * const KEY_LOCATION_HAS_APPROVED = @"hasApprovedLocationAccess";
NSString * const KEY_HAS_CALIBRATED = @"hasCalibrated";

NSString * const KEY_USES_SLEIPNIR = @"usesSleipnir";
NSString * const KEY_SLEIPNIR_ON_FRONT = @"sleipnirClipSideScreen";

NSString * const KEY_DID_LOGINOUT = @"DidLogInOut";
NSString * const KEY_IS_DROPBOXLINKED = @"isDropboxLinked";
NSString * const KEY_WINDMETERMODEL_CHANGED = @"WindmeterModelChange";
NSString * const KEY_HISTORY_SYNCED = @"HistorySynced";
NSString * const KEY_OPEN_LATEST_SUMMARY = @"OpenLatestSummary";

NSString * const KEY_MEASUREMENT_TIME_LIMITED = @"TimeLimited";

@implementation Property (Util)

+ (NSString *)getAsString:(NSString *)name {
    Property *property = [Property MR_findFirstByAttribute:@"name" withValue:name];
    if (property && property.value != (id)[NSNull null]) {
        return property.value;
    }
    else {
        return nil;
    }
}

+ (BOOL)getAsBoolean:(NSString *)name {
    NSString* value = [self getAsString:name];
    return [@"1" isEqualToString:value];
}

+ (BOOL)getAsBoolean:(NSString *)name defaultValue:(BOOL)defaultValue {
    NSString *value = [self getAsString:name];
    if (value) {
        return [@"1" isEqualToString:value];
    }
    else {
        return defaultValue;
    }
}

+ (NSNumber *)getAsInteger:(NSString *)name {
    NSString *value = [self getAsString:name];
    if (value == nil) {
        return nil;
    }
    return @([value integerValue]);
}

+ (NSNumber *)getAsInteger:(NSString *)name defaultValue:(int)defaultValue {
    NSString *value = [self getAsString:name];
    if (value == nil) {
        return [NSNumber numberWithInt:defaultValue];
    }
    return @([value integerValue]);
}

+ (NSNumber *)getAsLongLong:(NSString *)name {
    NSString *value = [self getAsString:name];
    if (value == nil) {
        return nil;
    }
    return @([value longLongValue]);
}

+ (NSNumber *)getAsDouble:(NSString *)name {
    NSString *value = [self getAsString:name];
    if (value == nil) {
        return nil;
    }
    return @([value doubleValue]);
}

+ (NSNumber *)getAsDouble:(NSString *)name defaultValue:(double)defaultValue {
    NSString *value = [self getAsString:name];
    if (value == nil) {
        return @(defaultValue);
    }
    return @([value doubleValue]);
}

+ (NSNumber *)getAsFloat:(NSString *)name {
    NSString *value = [self getAsString:name];
    if (value == nil) {
        return nil;
    }
    return @([value floatValue]);
}

+ (NSNumber *)getAsFloat:(NSString *)name defaultValue:(float)defaultValue {
    NSString *value = [self getAsString:name];
    if (value == nil) {
        return @(defaultValue);
    }
    return @([value floatValue]);
}

+ (NSDate *)getAsDate:(NSString *)name {
    NSString *value = [self getAsString:name];
    if (value == nil) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
}

+ (void)setAsString:(NSString *)value forKey:(NSString *)name {
    Property *property = [Property MR_findFirstByAttribute:@"name" withValue:name];
    if (!property) {
        property = [Property MR_createEntity];
        property.name = name;
    }
    property.value = value;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
}

+ (void)setAsBoolean:(BOOL)value forKey:(NSString *)name {
    [self setAsString:(value ? @"1" : @"0") forKey:name];
}

+ (void)setAsInteger:(NSNumber *)value forKey:(NSString *)name {
    [self setAsString:[value stringValue] forKey:name];
}

+ (void)setAsLongLong:(NSNumber *)value forKey:(NSString *)name {
    [self setAsString:[value stringValue] forKey:name];
}

+ (void)setAsDouble:(NSNumber *)value forKey:(NSString *)name {
    [self setAsString:[value stringValue] forKey:name];
}

+ (void)setAsFloat:(NSNumber *)value forKey:(NSString *) name {
    [self setAsString:[value stringValue] forKey:name];
}

+ (void)setAsDate:(NSDate *)value forKey:(NSString *)name {
    [self setAsString:[[NSNumber numberWithDouble:[value timeIntervalSince1970]] stringValue] forKey:name];
}

+ (NSArray *)getAsFloatArray:(NSString *)name {
    NSString *value = [self getAsString:name];
    if (value == nil || value.length == 0) {
        return nil;
    }
    NSArray *stringArray = [value componentsSeparatedByString:@","];
    NSMutableArray *floatArray = [NSMutableArray arrayWithCapacity:stringArray.count];
    for (int i = 0; i < stringArray.count; i++) {
        NSString *stringValue = stringArray[i];
        NSNumber *floatValue = [NSNumber numberWithFloat:[stringValue floatValue]];
        [floatArray addObject:floatValue];
    }
    return floatArray;
}

+ (void)setAsFloatArray:(NSArray *)value forKey:(NSString *)name {
    NSString *storedValue = @"";
    if (value != nil && value.count > 0) {
        storedValue = [value componentsJoinedByString:@","];
    }
    [self setAsString:storedValue forKey:name];
}

+ (BOOL)isMixpanelEnabled {
    return [Property getAsBoolean:KEY_ENABLE_MIXPANEL defaultValue:YES];
}

+ (BOOL)isMixpanelPeopleEnabled {
    return [Property getAsBoolean:KEY_ENABLE_MIXPANEL_PEOPLE defaultValue:YES];
}

+ (void)refreshHasWindMeter {
    if (![Property getAsBoolean:KEY_USER_HAS_WIND_METER defaultValue:NO]) {
        BOOL hasMeasurements = ([MeasurementSession MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"windSpeedAvg > 0"]] > 0);
        [Property setAsBoolean:hasMeasurements forKey:KEY_USER_HAS_WIND_METER];
    }
}

+ (NSDictionary *)getDeviceDictionary {
    NSNumber *timezoneOffsetMillis = [NSNumber numberWithLong:([[NSTimeZone localTimeZone] secondsFromGMT] * 1000L)];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                [Property getAsString:KEY_DEVICE_UUID], @"uuid",
                                @"Apple", @"vendor",
                                [Property getAsString:KEY_MODEL], @"model",
                                [Property getAsString:KEY_OS], @"os",
                                [Property getAsString:KEY_OS_VERSION], @"osVersion",
                                [Property getAsString:KEY_APP], @"app",
                                [Property getAsString:KEY_APP_VERSION], @"appVersion",
                                [Property getAsString:KEY_COUNTRY], @"country",
                                [Property getAsString:KEY_LANGUAGE], @"language",
                                timezoneOffsetMillis, @"timezoneOffset",
                                [UnitUtil jsonNameForWindSpeedUnit:[[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue]], @"windSpeedUnit",
                                nil];
    
    return dictionary;
}

@end
