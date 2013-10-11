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

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) NSDate *startTime;
@property (nonatomic, readonly) float avgWindSpeed;
@property (nonatomic, readonly) float maxWindSpeed;
@property (nonatomic) WindSpeedUnit windSpeedUnit;

- (id)initWithLocation:(CLLocationCoordinate2D)coord startTime:(NSDate*)startTime avgWindSpeed:(float)avgWindSpeed maxWindSpeed:(float)maxWindSpeed;

@end
