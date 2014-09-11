//
//  WindMeasurementController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "WindMeasurementController.h"

@implementation WindMeasurementController

- (void) start {
}

- (NSTimeInterval) stop {
    return 0.0;
}

- (enum WindMeterDeviceType) windMeterDeviceType {
    return 0;
}

- (NSString*) mixpanelWindMeterName {
    switch ([self windMeterDeviceType]) {
        case MjolnirWindMeterDeviceType:
            return @"Mjolnir";
        case SleipnirWindMeterDeviceType:
            return @"Sleipnir";
        default:
            return @"Unknown";
    }
}

@end
