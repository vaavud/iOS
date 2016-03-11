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

- (id)initWithStartTime:(NSDate *)startTime {
    self = [super init];
    if (self) {
	        _startTime = startTime;
    }
    return self;
}

- (id)initWithLocation:(CLLocationCoordinate2D)coordinate
         windDirection:(NSNumber *)direction {
    
    self = [super init];
    if (self) {
        _coordinate = coordinate;
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
