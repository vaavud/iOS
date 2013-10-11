//
//  MeasurementAnnotation.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 24/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "MeasurementAnnotation.h"

@implementation MeasurementAnnotation

- (id)initWithLocation:(CLLocationCoordinate2D)coordinate startTime:(NSDate*)startTime avgWindSpeed:(float)avgWindSpeed maxWindSpeed:(float)maxWindSpeed {
    self = [super init];
    if (self) {
        _coordinate = coordinate;
        _startTime = startTime;
        _avgWindSpeed = avgWindSpeed;
        _maxWindSpeed = maxWindSpeed;
    }
    return self;
}

- (NSString*) title {
    return [self formatWindSpeed:self.avgWindSpeed];
}

- (NSString*) formatWindSpeed:(double) value {
    double localizedValue = [UnitUtil displayWindSpeedFromDouble:value unit:self.windSpeedUnit];
    if (localizedValue > 100.0) {
        return [NSString stringWithFormat: @"%.0f %@", localizedValue, [UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit]];
    }
    else {
        return [NSString stringWithFormat: @"%.1f %@", localizedValue, [UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit]];
    }
}

- (NSString*) description {
    return [NSString stringWithFormat:@"[coordinate=(%f,%f), startTime=%@, avgWindSpeed=%f, maxWindSpeed=%f]", self.coordinate.latitude, self.coordinate.longitude, self.startTime, self.avgWindSpeed, self.maxWindSpeed];
}
@end
