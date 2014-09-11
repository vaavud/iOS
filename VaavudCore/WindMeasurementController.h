//
//  WindMeasurementController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

enum WindMeterDeviceType : NSUInteger {
    MjolnirWindMeterDeviceType = 1,
    SleipnirWindMeterDeviceType = 2
};

@protocol WindMeasurementControllerDelegate <NSObject>

- (void) addSpeedMeasurement:(NSNumber*)currentSpeed avgSpeed:(NSNumber*)avgSpeed maxSpeed:(NSNumber*)maxSpeed;

@optional
- (void) updateDirection:(NSNumber*)direction;
- (void) updateLocation:(NSNumber*)latitude longitude:(NSNumber*)longitude;
- (void) updateTemperature:(NSNumber*)temperature;
- (void) changedValidity:(BOOL)isValid dynamicsIsValid:(BOOL)dynamicsIsValid;
- (void) deviceConnected:(enum WindMeterDeviceType)device;
- (void) deviceDisconnected:(enum WindMeterDeviceType)device;
- (void) measuringStoppedByModel;

@end

@interface WindMeasurementController : NSObject

@property (nonatomic, weak) id<WindMeasurementControllerDelegate> delegate;

- (void) start;
- (NSTimeInterval) stop;
- (enum WindMeterDeviceType) windMeterDeviceType;
- (NSString*) mixpanelWindMeterName;

@end
