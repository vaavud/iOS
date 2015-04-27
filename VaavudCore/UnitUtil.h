//
//  Measure.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

#define STATUTE_MILE 1609.344 // m
#define NAUTICAL_MILE 1852.0 // m

typedef NS_ENUM(NSInteger, WindSpeedUnit) {
    WindSpeedUnitKMH     = 0,
    WindSpeedUnitMS      = 1,
    WindSpeedUnitMPH     = 2,
    WindSpeedUnitKN      = 3,
    WindSpeedUnitBFT     = 4
};

@interface UnitUtil : NSObject

+ (WindSpeedUnit)nextWindSpeedUnit:(WindSpeedUnit)unit;
+ (WindSpeedUnit)windSpeedUnitForCountry:(NSString *)countryCode;
+ (NSString *)jsonNameForWindSpeedUnit:(WindSpeedUnit)unit;
+ (NSString *)displayNameForWindSpeedUnit:(WindSpeedUnit)unit;
+ (double)displayWindSpeedFromDouble:(double)windSpeedMS unit:(WindSpeedUnit)unit;
+ (NSNumber *)displayWindSpeedFromNumber:(NSNumber *)windSpeedMS unit:(WindSpeedUnit)unit;
+ (NSString *)englishDisplayNameForWindSpeedUnit:(WindSpeedUnit)unit;

+ (NSString *)displayNameForDirection:(NSNumber *)direction;
+ (NSString *)displayNameForDirectionUnit:(NSInteger)directionUnit;

+ (CGAffineTransform)transformForDirection:(NSNumber *)direction;

@end
