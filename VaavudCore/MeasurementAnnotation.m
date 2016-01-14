//
//  MeasurementAnnotation.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 24/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "MeasurementAnnotation.h"
#import "Vaavud-Swift.h"

@implementation MeasurementAnnotation

- (id)initWithLocation:(CLLocationCoordinate2D)coord  windDirection:(NSNumber *)direction {
    return [self initWithLocation:coord sessionKey:nil startTime:nil avgWindSpeed:0.0F maxWindSpeed:0.0F windDirection:direction];
}

- (id)initWithLocation:(CLLocationCoordinate2D)coordinate
            sessionKey:(NSString *)sessionKey
             startTime:(NSDate*)startTime
          avgWindSpeed:(float)avgWindSpeed
          maxWindSpeed:(float)maxWindSpeed
         windDirection:(NSNumber *)direction {
    
    self = [super init];
    if (self) {
        _coordinate = coordinate;
        _sessionKey = sessionKey;
        _startTime = startTime;
        _avgWindSpeed = avgWindSpeed;
        _maxWindSpeed = maxWindSpeed;
        _windDirection = direction;
    }
    return self;
}

- (NSString *)title {
    return [[VaavudFormatter shared] localizedSpeed:self.avgWindSpeed digits:2];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[coordinate=(%f,%f), startTime=%@, avgWindSpeed=%f, maxWindSpeed=%f]", self.coordinate.latitude, self.coordinate.longitude, self.startTime, self.avgWindSpeed, self.maxWindSpeed];
}

@end
