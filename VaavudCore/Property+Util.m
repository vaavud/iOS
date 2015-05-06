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
#import <VaavudElectronicSDK/VEVaavudElectronicSDK.h>
#import <VaavudElectronicSDK/VEVaavudElectronicSDK+Analysis.h>

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
                                @([[VEVaavudElectronicSDK sharedVaavudElectronic] getVolume]), @"sleipnirVolume",
                                [[VEVaavudElectronicSDK sharedVaavudElectronic] getEncoderCoefficients], @"sleipnirEncoderCoefficients",
                                nil];
    
    return dictionary;
}

@end
