//
//  Measure.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "UnitUtil.h"

@implementation UnitUtil

static NSSet* countriesUsingMph;

+ (void) initialize {
    countriesUsingMph = [NSSet setWithObjects:@"US", @"UM", @"GB", @"CA", @"VG", @"VI", nil];
}

+ (WindSpeedUnit) nextWindSpeedUnit:(WindSpeedUnit) unit {
    unit++;
    if (unit > 3) {
        unit = 0;
    }
    return unit;
}

+ (WindSpeedUnit) windSpeedUnitForCountry:(NSString*) countryCode {
    if ([countriesUsingMph containsObject:countryCode]) {
        return WindSpeedUnitMPH;
    }
    else {
        return WindSpeedUnitMS;
    }
}

+ (NSString*) jsonNameForWindSpeedUnit:(WindSpeedUnit) unit {
    if (unit == WindSpeedUnitMS) {
        return @"MS";
    }
    else if (unit == WindSpeedUnitMPH) {
        return @"MPH";
    }
    else if (unit == WindSpeedUnitKN) {
        return @"KN";
    }
    else {
        return @"KMH";
    }
}

+ (NSString*) displayNameForWindSpeedUnit:(WindSpeedUnit) unit {
    if (unit == WindSpeedUnitMS) {
        return @"m/s";
    }
    else if (unit == WindSpeedUnitMPH) {
        return @"mph";
    }
    else if (unit == WindSpeedUnitKN) {
        return @"kt";
    }
    else {
        // default to km/h
        return @"km/h";
    }
}

+ (double) displayWindSpeedFromDouble:(double) windSpeedMS unit:(WindSpeedUnit) unit {
    if (unit == WindSpeedUnitMS) {
        return windSpeedMS;
    }
    else if (unit == WindSpeedUnitMPH) {
        return windSpeedMS * 3600.0 / STATUTE_MILE;
    }
    else if (unit == WindSpeedUnitKN) {
        return windSpeedMS * 3600.0 / NAUTICAL_MILE;
    }
    else {
        // default to km/h
        return windSpeedMS * 3.6;
    }
}

+ (NSNumber*) displayWindSpeedFromNumber:(NSNumber*) windSpeedMS unit:(WindSpeedUnit) unit {
    return [NSNumber numberWithDouble:[UnitUtil displayWindSpeedFromDouble:[windSpeedMS doubleValue] unit:unit]];
}

@end