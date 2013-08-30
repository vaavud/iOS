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
    if (unit > 4) {
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
    else if (unit == WindSpeedUnitBFT){
        return @"BFT";
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
    else if (unit == WindSpeedUnitBFT) {
        return @"bft";
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
    else if (unit == WindSpeedUnitBFT) {
        // conversion table from http://en.wikipedia.org/wiki/Beaufort_scale
        if (windSpeedMS < 0.3)
            return 0;
        else if (windSpeedMS < 1.6)
            return 1;
        else if (windSpeedMS < 3.5)
            return 2;
        else if (windSpeedMS < 5.5)
            return 3;
        else if (windSpeedMS < 8.0)
            return 4;
        else if (windSpeedMS < 10.8)
            return 5;
        else if (windSpeedMS < 13.9)
            return 6;
        else if (windSpeedMS < 17.2)
            return 7;
        else if (windSpeedMS < 20.8)
            return 8;
        else if (windSpeedMS < 24.5)
            return 9;
        else if (windSpeedMS < 28.5)
            return 10;
        else if (windSpeedMS < 32.7)
            return 11;
        else
            return 12;
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
