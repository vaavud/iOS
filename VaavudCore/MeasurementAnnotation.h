//
//  MeasurementAnnotation.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 24/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MeasurementAnnotation : NSObject <MKAnnotation> {}

@property (nonatomic, readonly) NSDate *startTime;

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) float avgWindSpeed;
@property (nonatomic) float maxWindSpeed;
@property (nonatomic) NSNumber *windDirection;

@property (nonatomic) BOOL isFinished;
@property (nonatomic) BOOL isOnMap;

- (id)initWithStartTime:(NSDate *)startTime;
- (id)initWithLocation:(CLLocationCoordinate2D)coord windDirection:(NSNumber *)direction;

@end
