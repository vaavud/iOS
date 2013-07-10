//
//  Property+Util.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 01/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "Property+Util.h"

@implementation Property (Util)

+ (NSString*) getAsString:(NSString *)name {
    Property *property = [Property findFirstByAttribute:@"name" withValue:name];
    if (property && property.value) {
        return property.value;
    }
    else {
        return nil;
    }
}

+ (BOOL) getAsBoolean:(NSString *)name {
    NSString* value = [self getAsString:name];
    return [value isEqualToString:@"1"];
}

+ (void) setAsString:(NSString *)value forKey:(NSString*)name {
    Property *property = [Property findFirstByAttribute:@"name" withValue:name];
    if (!property) {
        property = [Property createEntity];
        property.name = name;
    }
    property.value = value;
    [[NSManagedObjectContext defaultContext] saveToPersistentStoreWithCompletion:nil];
}

+ (void) setAsBoolean:(BOOL)value forKey:(NSString *)name {
    [self setAsString:(value ? @"1" : @"0") forKey:name];
}

+ (NSDictionary *) getDeviceDictionary {
    
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
                                [Property getAsString:KEY_MEASURE], @"measure",
                                nil];
    
    return dictionary;
}


@end
