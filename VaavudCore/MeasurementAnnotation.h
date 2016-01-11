//
//  MeasurementAnnotation.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 24/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "UnitUtil.h"

@interface MeasurementAnnotation : NSObject <MKAnnotation> {}

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) NSDate *startTime;
@property (nonatomic) float avgWindSpeed;
@property (nonatomic) float maxWindSpeed;
@property (nonatomic, readonly) NSString *sessionKey;
@property (nonatomic) NSNumber *windDirection;
@property (nonatomic) WindSpeedUnit windSpeedUnit;

- (id)initWithLocation:(CLLocationCoordinate2D)coord windDirection:(NSNumber *)direction;
- (id)initWithLocation:(CLLocationCoordinate2D)coord
            sessionKey: (NSString *)sessionKey
             startTime:(NSDate *)startTime
          avgWindSpeed:(float)avgWindSpeed
          maxWindSpeed:(float)maxWindSpeed
         windDirection:(NSNumber *)direction;

@end
