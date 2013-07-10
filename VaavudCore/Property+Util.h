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
static NSString * const KEY_MEASURE = @"measure";
static NSString * const KEY_HAS_PROMPTED_FOR_LOCATION = @"hasPromptedForLocation";

@interface Property (Util)

+ (NSString*) getAsString:(NSString*) name;

+ (BOOL) getAsBoolean:(NSString*) name;

+ (void) setAsString:(NSString*) value forKey:(NSString*) name;

+ (void) setAsBoolean:(BOOL) value forKey:(NSString*) name;

+ (NSDictionary *) getDeviceDictionary;

@end
