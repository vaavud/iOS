//
//  WindMeasurementController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WindMeterDeviceType) {
    UnknownWindMeterDeviceType = 0,
    MjolnirWindMeterDeviceType = 1,
    SleipnirWindMeterDeviceType = 2
};

@protocol WindMeasurementControllerDelegate <NSObject>

- (void)addSpeedMeasurement:(NSNumber *)currentSpeed avgSpeed:(NSNumber *)avgSpeed maxSpeed:(NSNumber *)maxSpeed;

@optional
- (void)updateDirection:(NSNumber *)direction;
- (void)updateDirectionLocal:(NSNumber *)direction;
- (void)updateLocation:(NSNumber *)latitude longitude:(NSNumber *)longitude;
- (void)updateTemperature:(NSNumber *)temperature;
- (void)changedValidity:(BOOL)isValid dynamicsIsValid:(BOOL)dynamicsIsValid;
- (void)deviceAvailabilityChanged:(WindMeterDeviceType)device andAvailability:(BOOL)available;
- (void)deviceConnected:(WindMeterDeviceType)device;
- (void)deviceDisconnected:(WindMeterDeviceType)device;
- (void)measuringStoppedByModel;

@end

@interface WindMeasurementController : NSObject

@property (nonatomic, weak) id<WindMeasurementControllerDelegate> delegate;

- (void)start;
- (NSTimeInterval)stop;
- (WindMeterDeviceType)windMeterDeviceType;
- (NSString *)mixpanelWindMeterName;

@end
