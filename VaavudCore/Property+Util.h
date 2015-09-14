//
//  Properties+Util.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 01/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "Property.h"

extern NSString * const KEY_CREATION_TIME;
extern NSString * const KEY_DEVICE_UUID;
extern NSString * const KEY_AUTH_TOKEN;
extern NSString * const KEY_APP;
extern NSString * const KEY_APP_VERSION;
extern NSString * const KEY_APP_BUILD;
extern NSString * const KEY_OS;
extern NSString * const KEY_OS_VERSION;
extern NSString * const KEY_MODEL;
extern NSString * const KEY_COUNTRY;
extern NSString * const KEY_LANGUAGE;
extern NSString * const KEY_WIND_SPEED_UNIT;
extern NSString * const KEY_DIRECTION_UNIT;
extern NSString * const KEY_MAP_HOURS;
extern NSString * const KEY_HAS_PROMPTED_FOR_LOCATION;
extern NSString * const KEY_FREQUENCY_START;
extern NSString * const KEY_FREQUENCY_FACTOR;
extern NSString * const KEY_FFT_LENGTH;
extern NSString * const KEY_FFT_DATA_LENGTH;
extern NSString * const KEY_FFT_MAG_MIN;
extern NSString * const KEY_ALGORITHM;
extern NSString * const KEY_ANALYTICS_GRID_DEGREE;
extern NSString * const KEY_HOUR_OPTIONS;
extern NSString * const KEY_ENABLE_MIXPANEL;
extern NSString * const KEY_ENABLE_MIXPANEL_PEOPLE;
extern NSString * const KEY_ENABLE_FACEBOOK_DISCLAIMER;
extern NSString * const KEY_ENABLE_SHARE_DIALOG;
extern NSString * const KEY_HAS_SEEN_INTRO_FLOW;
extern NSString * const KEY_MAP_GUIDE_MARKER_SHOWN;
extern NSString * const KEY_MAP_GUIDE_TIME_INTERVAL_SHOWN;
extern NSString * const KEY_MAP_GUIDE_ZOOM_SHOWN;
extern NSString * const KEY_SLEIPNIR_CLIP_SIDE_SCREEN;

// User-related properties
extern NSString * const KEY_EMAIL;
extern NSString * const KEY_FACEBOOK_USER_ID;
extern NSString * const KEY_FACEBOOK_ACCESS_TOKEN;
extern NSString * const KEY_USER_ID;
extern NSString * const KEY_FIRST_NAME;
extern NSString * const KEY_LAST_NAME;
extern NSString * const KEY_AUTHENTICATION_STATE;
extern NSString * const KEY_USER_HAS_WIND_METER;

// Agri-related properties
extern NSString * const KEY_AGRI_VALID_SUBSCRIPTION;
extern NSString * const KEY_AGRI_DEFAULT_REDUCING_EQUIPMENT;
extern NSString * const KEY_AGRI_DEFAULT_DOSE;
extern NSString * const KEY_AGRI_DEFAULT_BOOM_HEIGHT;
extern NSString * const KEY_AGRI_DEFAULT_SPRAY_QUALITY;

// This is new
extern NSString * const KEY_AGRI_TEST_MODE;
extern NSString * const KEY_HAS_SEEN_UPGRADE_FLOW;

extern NSString * const KEY_TEMPERATURE_UNIT;
extern NSString * const KEY_PRESSURE_UNIT;
extern NSString * const KEY_UNIT_CHANGED;

extern NSString * const KEY_LOCATION_HAS_ASKED;
extern NSString * const KEY_LOCATION_HAS_APPROVED;
extern NSString * const KEY_HAS_CALIBRATED;

extern NSString * const KEY_USES_SLEIPNIR;
extern NSString * const KEY_SLEIPNIR_ON_FRONT;

extern NSString * const KEY_DID_LOGINOUT;
extern NSString * const KEY_IS_DROPBOXLINKED;
extern NSString * const KEY_WINDMETERMODEL_CHANGED;
extern NSString * const KEY_HISTORY_SYNCED;
extern NSString * const KEY_OPEN_LATEST_SUMMARY;

extern NSString * const KEY_MEASUREMENT_TIME_UNLIMITED;

extern NSString * const KEY_SESSION_UPDATED;

extern NSString * const KEY_HAS_SEEN_TRISCREEN_FLOW;

extern NSString * const KEY_MAP_GUIDE_MEASURE_BUTTON_SHOWN;

extern NSString * const KEY_MAP_GUIDE_MEASURE_BUTTON_SHOWN_TODAY;

extern NSString * const KEY_MAP_FORECAST_HOURS;


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
