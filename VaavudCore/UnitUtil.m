//
//  Measure.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "UnitUtil.h"

@implementation UnitUtil

static NSSet *countriesUsingMph;
static NSArray *directionNameStrings;
static NSArray *directionImageStrings;
static NSArray *mapDirectionImageStrings;

+ (void)initialize {
    countriesUsingMph = [NSSet setWithObjects:@"US", @"UM", @"GB", @"CA", @"VG", @"VI", nil];
    directionNameStrings = @[@"DIRECTION_N", @"DIRECTION_NNE", @"DIRECTION_NE", @"DIRECTION_ENE", @"DIRECTION_E", @"DIRECTION_ESE", @"DIRECTION_SE", @"DIRECTION_SSE", @"DIRECTION_S", @"DIRECTION_SSW", @"DIRECTION_SW", @"DIRECTION_WSW", @"DIRECTION_W", @"DIRECTION_WNW", @"DIRECTION_NW", @"DIRECTION_NNW"];
    
#ifdef AGRI
    // AGRICULTURE APP
    directionImageStrings = @[@"windarrow_green_N.png", @"windarrow_green_NNE.png", @"windarrow_green_NE.png", @"windarrow_green_ENE.png", @"windarrow_green_E.png", @"windarrow_green_ESE.png", @"windarrow_green_SE.png", @"windarrow_green_SSE.png", @"windarrow_green_S.png", @"windarrow_green_SSW.png", @"windarrow_green_SW.png", @"windarrow_green_WSW.png", @"windarrow_green_W.png", @"windarrow_green_WNW.png", @"windarrow_green_NW.png", @"windarrow_green_NNW.png"];
#elif CORE
    // CORE VAAVUD APP
    directionImageStrings = @[@"windarrow_red_N.png", @"windarrow_red_NNE.png", @"windarrow_red_NE.png", @"windarrow_red_ENE.png", @"windarrow_red_E.png", @"windarrow_red_ESE.png", @"windarrow_red_SE.png", @"windarrow_red_SSE.png", @"windarrow_red_S.png", @"windarrow_red_SSW.png", @"windarrow_red_SW.png", @"windarrow_red_WSW.png", @"windarrow_red_W.png", @"windarrow_red_WNW.png", @"windarrow_red_NW.png", @"windarrow_red_NNW.png"];
#endif
    
    mapDirectionImageStrings = @[@"mapmarker_w_direction_N.png", @"mapmarker_w_direction_NNE.png", @"mapmarker_w_direction_NE.png", @"mapmarker_w_direction_ENE.png", @"mapmarker_w_direction_E.png", @"mapmarker_w_direction_ESE.png", @"mapmarker_w_direction_SE.png", @"mapmarker_w_direction_SSE.png", @"mapmarker_w_direction_S.png", @"mapmarker_w_direction_SSW.png", @"mapmarker_w_direction_SW.png", @"mapmarker_w_direction_WSW.png", @"mapmarker_w_direction_W.png", @"mapmarker_w_direction_WNW.png", @"mapmarker_w_direction_NW.png", @"mapmarker_w_direction_NNW.png"];
}

+ (WindSpeedUnit)nextWindSpeedUnit:(WindSpeedUnit)unit {
    unit++;
    if (unit > 4) {
        unit = 0;
    }
    return unit;
}

+ (WindSpeedUnit)windSpeedUnitForCountry:(NSString *)countryCode {
    if ([countriesUsingMph containsObject:countryCode]) {
        return WindSpeedUnitMPH;
    }
    else {
        return WindSpeedUnitMS;
    }
}

+ (NSString *)jsonNameForWindSpeedUnit:(WindSpeedUnit)unit {
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

+ (NSString *)displayNameForWindSpeedUnit:(WindSpeedUnit)unit {
    if (unit == WindSpeedUnitMS) {
        return NSLocalizedString(@"UNIT_MS", nil);
    }
    else if (unit == WindSpeedUnitMPH) {
        return NSLocalizedString(@"UNIT_MPH", nil);
    }
    else if (unit == WindSpeedUnitKN) {
        return NSLocalizedString(@"UNIT_KN", nil);
    }
    else if (unit == WindSpeedUnitBFT) {
        return NSLocalizedString(@"UNIT_BFT", nil);
    }
    else {
        // default to km/h
        return NSLocalizedString(@"UNIT_KMH", nil);
    }
}

+ (NSString *)englishDisplayNameForWindSpeedUnit:(WindSpeedUnit)unit {
    if (unit == WindSpeedUnitMS) {
        return @"m/s";
    }
    else if (unit == WindSpeedUnitMPH) {
        return @"mph";
    }
    else if (unit == WindSpeedUnitKN) {
        return @"knots";
    }
    else if (unit == WindSpeedUnitBFT) {
        return @"bft";
    }
    else {
        // default to km/h
        return @"km/h";
    }
}

+ (double)displayWindSpeedFromDouble:(double)windSpeedMS unit:(WindSpeedUnit)unit {
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

+ (NSNumber *)displayWindSpeedFromNumber:(NSNumber *)windSpeedMS unit:(WindSpeedUnit)unit {
    return [NSNumber numberWithDouble:[UnitUtil displayWindSpeedFromDouble:[windSpeedMS doubleValue] unit:unit]];
}

+ (NSString *)displayNameForDirection:(NSNumber *)direction {
    if (!direction) {
        return @"-";
    }
    NSInteger index = [self directionIndex:[direction doubleValue]];
    return NSLocalizedString(directionNameStrings[index], nil);
}

+ (NSString *)imageNameForDirection:(NSNumber *)direction {
    if (!direction) {
        return nil;
    }
    NSInteger index = [self directionIndex:[direction doubleValue]];
    return directionImageStrings[index];
}

+ (NSString *)mapImageNameForDirection:(NSNumber *)direction {
    if (!direction) {
        return nil;
    }
    NSInteger index = [self directionIndex:[direction doubleValue]];
    return mapDirectionImageStrings[index];
}

+ (NSInteger)directionIndex:(double)direction {
    if (direction < 0.0 || direction >= 360.0) {
        direction = fmod(direction, 360.0);
    }
    NSInteger index = round((direction / 360.0) * 16.0);
    if (index == 16) {
        index = 0;
    }
    return index;
}

+ (NSString *)displayNameForDirectionUnit:(NSInteger)directionUnit {
    switch (directionUnit) {
        case 0:
            return NSLocalizedString(@"DIRECTION_CARDINAL", nil);
        case 1:
            return NSLocalizedString(@"DIRECTION_DEGREES", nil);
        default:
            NSLog(@"[UnitUtil] Unknown direction unit %ld", (long)directionUnit);
            return @"_";
    }
}

@end
