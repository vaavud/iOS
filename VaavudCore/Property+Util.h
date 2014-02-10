//
//  Properties+Util.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 01/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "Property.h"

static NSString * const KEY_DEVICE_UUID = @"deviceUuid";
static NSString * const KEY_AUTH_TOKEN = @"authToken";
static NSString * const KEY_APP = @"app";
static NSString * const KEY_APP_VERSION = @"appVersion";
static NSString * const KEY_APP_BUILD = @"appBuild";
static NSString * const KEY_OS = @"os";
static NSString * const KEY_OS_VERSION = @"osVersion";
static NSString * const KEY_MODEL = @"model";
static NSString * const KEY_COUNTRY = @"country";
static NSString * const KEY_LANGUAGE = @"language";
static NSString * const KEY_WIND_SPEED_UNIT = @"windSpeedUnit";
static NSString * const KEY_HAS_PROMPTED_FOR_LOCATION = @"hasPromptedForLocation";
static NSString * const KEY_FREQUENCY_START = @"frequencyStart";
static NSString * const KEY_FREQUENCY_FACTOR = @"frequencyFactor";
static NSString * const KEY_FFT_LENGTH = @"fftLength";
static NSString * const KEY_FFT_DATA_LENGTH = @"fftDataLength";
static NSString * const KEY_ALGORITHM = @"algorithm";
static NSString * const KEY_ANALYTICS_GRID_DEGREE = @"analyticsGridDegree";
static NSString * const KEY_HOUR_OPTIONS = @"hourOptions";

// User-related properties
static NSString * const KEY_EMAIL = @"email";


@interface Property (Util)

+ (NSString*) getAsString:(NSString*) name;
+ (BOOL) getAsBoolean:(NSString*) name;
+ (NSNumber*) getAsInteger:(NSString*) name;
+ (NSNumber*) getAsDouble:(NSString*) name;
+ (NSArray*) getAsFloatArray:(NSString*) name;
+ (void) setAsString:(NSString*) value forKey:(NSString*) name;
+ (void) setAsBoolean:(BOOL) value forKey:(NSString*) name;
+ (void) setAsInteger:(NSNumber*) value forKey:(NSString*) name;
+ (void) setAsDouble:(NSNumber*) value forKey:(NSString*) name;
+ (void) setAsFloatArray:(NSArray*) value forKey:(NSString*) name;

+ (NSDictionary *) getDeviceDictionary;

@end
