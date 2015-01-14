//
//  Properties+Util.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 01/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "Property.h"

static NSString * const KEY_CREATION_TIME = @"creationTime";
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
static NSString * const KEY_DIRECTION_UNIT = @"directionUnit";
static NSString * const KEY_MAP_HOURS = @"mapHours";
static NSString * const KEY_HAS_PROMPTED_FOR_LOCATION = @"hasPromptedForLocation";
static NSString * const KEY_FREQUENCY_START = @"frequencyStart";
static NSString * const KEY_FREQUENCY_FACTOR = @"frequencyFactor";
static NSString * const KEY_FFT_LENGTH = @"fftLength";
static NSString * const KEY_FFT_DATA_LENGTH = @"fftDataLength";
static NSString * const KEY_FFT_MAG_MIN = @"fftMagMin";
static NSString * const KEY_ALGORITHM = @"algorithm";
static NSString * const KEY_ANALYTICS_GRID_DEGREE = @"analyticsGridDegree";
static NSString * const KEY_HOUR_OPTIONS = @"hourOptions";
static NSString * const KEY_ENABLE_MIXPANEL = @"enableMixPanel";
static NSString * const KEY_ENABLE_MIXPANEL_PEOPLE = @"enableMixPanelPeople";
static NSString * const KEY_ENABLE_FACEBOOK_DISCLAIMER = @"enableFacebookDisclaimer";
static NSString * const KEY_ENABLE_SHARE_DIALOG = @"enableShareDialog";
static NSString * const KEY_HAS_SEEN_INTRO_FLOW = @"hasSeenIntroFlow";
static NSString * const KEY_MAP_GUIDE_MARKER_SHOWN = @"mapGuideMarkerShown";
static NSString * const KEY_MAP_GUIDE_TIME_INTERVAL_SHOWN = @"mapGuideTimeIntervalShown";
static NSString * const KEY_MAP_GUIDE_ZOOM_SHOWN = @"mapGuideZoomShown";

// User-related properties
static NSString * const KEY_EMAIL = @"email";
static NSString * const KEY_FACEBOOK_USER_ID = @"facebookUserId";
static NSString * const KEY_FACEBOOK_ACCESS_TOKEN = @"facebookAccessToken";
static NSString * const KEY_USER_ID = @"userId";
static NSString * const KEY_FIRST_NAME = @"firstName";
static NSString * const KEY_LAST_NAME = @"lastName";
static NSString * const KEY_AUTHENTICATION_STATE = @"authenticationState";
static NSString * const KEY_USER_HAS_WIND_METER = @"userHasWindMeter";

// Agri-related properties

static NSString * const KEY_AGRI_VALID_SUBSCRIPTION = @"agriValidSubscription";
static NSString * const KEY_AGRI_DEFAULT_REDUCING_EQUIPMENT = @"agriDefaultReducingEquipment";
static NSString * const KEY_AGRI_DEFAULT_DOSE = @"agriDefaultDose";
static NSString * const KEY_AGRI_DEFAULT_BOOM_HEIGHT = @"agriDefaultBoomHeight";
static NSString * const KEY_AGRI_DEFAULT_SPRAY_QUALITY = @"agriDefaultSprayQuality";

// This is new
static NSString * const KEY_AGRI_TEST_MODE = @"testMode";


@interface Property (Util)

+ (NSString *)getAsString:(NSString *)name;
+ (BOOL)getAsBoolean:(NSString *)name;
+ (BOOL)getAsBoolean:(NSString *)name defaultValue:(BOOL)defaultValue;
+ (NSNumber *)getAsInteger:(NSString *)name;
+ (NSNumber *)getAsInteger:(NSString *)name defaultValue:(int)defaultValue;
+ (NSNumber *)getAsLongLong:(NSString *)name;
+ (NSNumber *)getAsDouble:(NSString *)name;
+ (NSNumber *)getAsDouble:(NSString *)name defaultValue:(double)defaultValue;
+ (NSNumber *)getAsFloat:(NSString *)name;
+ (NSNumber *)getAsFloat:(NSString *)name defaultValue:(float)defaultValue;
+ (NSDate *)getAsDate:(NSString *)name;
+ (NSArray *)getAsFloatArray:(NSString *)name;
+ (void)setAsString:(NSString *)value forKey:(NSString *)name;
+ (void)setAsBoolean:(BOOL)value forKey:(NSString *)name;
+ (void)setAsInteger:(NSNumber *)value forKey:(NSString *)name;
+ (void)setAsLongLong:(NSNumber *)value forKey:(NSString *)name;
+ (void)setAsDouble:(NSNumber *)value forKey:(NSString *)name;
+ (void)setAsFloat:(NSNumber *)value forKey:(NSString *)name;
+ (void)setAsDate:(NSDate *)value forKey:(NSString *)name;
+ (void)setAsFloatArray:(NSArray *)value forKey:(NSString *)name;

+ (BOOL)isMixpanelEnabled;
+ (BOOL)isMixpanelPeopleEnabled;
+ (void)refreshHasWindMeter;

+ (NSDictionary *)getDeviceDictionary;

@end
