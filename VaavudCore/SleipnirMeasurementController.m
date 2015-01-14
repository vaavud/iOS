//
//  SleipnirMeasurementController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 05/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "SleipnirMeasurementController.h"
#import "SharedSingleton.h"

@interface SleipnirMeasurementController ()

@property (nonatomic) BOOL isStarted;
@property (nonatomic, strong) NSDate *startTime;

@property (nonatomic) double accumulatedSpeed;
@property (nonatomic) double maxSpeed;
@property (nonatomic) int numberOfSpeedSamples;
@property (nonatomic, strong) NSNumber *averageSpeed;
@property (nonatomic, strong) NSNumber *direction;

@end

@implementation SleipnirMeasurementController

SHARED_INSTANCE

- (id)init {
    self = [super init];
    
    if (self) {
        [self resetMeasurementData];
        VEVaavudElectronicSDK *sdk = [VEVaavudElectronicSDK sharedVaavudElectronic];
        self.isDeviceConnected = sdk.sleipnirAvailable;
        
        [sdk addListener:self];
    }
    
    return self;
}

- (void)resetMeasurementData {
    self.isStarted = NO;
    self.accumulatedSpeed = 0.0;
    self.maxSpeed = 0.0;
    self.numberOfSpeedSamples = 0;
    self.averageSpeed = nil;
    self.direction = nil;
}

- (enum WindMeterDeviceType)windMeterDeviceType {
    return SleipnirWindMeterDeviceType;
}

- (void)start {
    [self resetMeasurementData];
    self.isStarted = YES;
    self.startTime = [NSDate date];
    [[VEVaavudElectronicSDK sharedVaavudElectronic] start];
}

- (NSTimeInterval)stop {
    
    if (!self.isStarted) {
        // don't do anything if we're already stopped
        return 0.0;
    }
    
    self.isStarted = NO;
    [[VEVaavudElectronicSDK sharedVaavudElectronic] stop];
    NSTimeInterval durationSeconds = [[NSDate date] timeIntervalSinceDate:self.startTime];
    return durationSeconds;
}

- (void)sleipnirAvailabliltyChanged:(BOOL)available {
    self.isDeviceConnected = available;
    
    if ([self.delegate respondsToSelector:@selector(deviceAvailabilityChanged:andAvailability:)]) {
        [self.delegate deviceAvailabilityChanged:SleipnirWindMeterDeviceType andAvailability:available];
    }
    
    if (available) {
        NSLog(@"[SleipnirMeasurementController] sleipnirAvailabliltyChanged - available");
    }
    else {
        NSLog(@"[SleipnirMeasurementController] sleipnirAvailabliltyChanged - Not available");
    }
}

- (void)deviceConnectedTypeSleipnir:(BOOL)sleipnir {
    if (sleipnir) {
        NSLog(@"[SleipnirMeasurementController] deviceConnected - Sleipnir");
    }
    else {
        NSLog(@"[SleipnirMeasurementController] deviceConnected - Unknown");
    }
    
    if ([self.delegate respondsToSelector:@selector(deviceConnected:)]) {
        enum WindMeterDeviceType deviceType = sleipnir ? SleipnirWindMeterDeviceType : UnknownWindMeterDeviceType;
        [self.delegate deviceConnected:deviceType];
    }
}


- (void)deviceDisconnectedTypeSleipnir:(BOOL)sleipnir {
    if (sleipnir) {
        NSLog(@"[SleipnirMeasurementController] deviceDisconnected - Sleipnir");
    }
    else {
        NSLog(@"[SleipnirMeasurementController] deviceDisconnected - Unknown");
    }
    
    if ([self.delegate respondsToSelector:@selector(deviceDisconnected:)]) {
        enum WindMeterDeviceType deviceType = (sleipnir) ? SleipnirWindMeterDeviceType : UnknownWindMeterDeviceType;
        [self.delegate deviceDisconnected:deviceType];
    }
}

- (void)deviceConnectedChecking {
    NSLog(@"[SleipnirMeasurementController] devicePlugedInChecking");
}

- (void)newSpeed:(NSNumber *)speed {
    //NSLog(@"[SleipnirMeasurementController] newSpeed=%@", speed);
    
    // make sure we don't do anything with new data after the user has clicked stop
    if (self.isStarted && speed) {
        double currentSpeed = [speed doubleValue];
        self.accumulatedSpeed += currentSpeed;
        self.numberOfSpeedSamples++;
        self.averageSpeed = [NSNumber numberWithDouble:(self.accumulatedSpeed / self.numberOfSpeedSamples)];
        self.maxSpeed = MAX(self.maxSpeed, currentSpeed);
        
        if (self.delegate) {
            [self.delegate addSpeedMeasurement:speed avgSpeed:self.averageSpeed maxSpeed:[NSNumber numberWithDouble:self.maxSpeed]];
        }
    }
}

- (void)newWindDirection:(NSNumber *)windDirection {
    // make sure we don't do anything with new data after the user has clicked stop
    if (self.isStarted && windDirection) {
        self.direction = windDirection;
        
        if ([self.delegate respondsToSelector:@selector(updateDirection:)]) {
            [self.delegate updateDirection:self.direction];
        }
    }
}

- (void)newWindAngleLocal:(NSNumber *)angle {
    if (self.isStarted && angle) {
        if ([self.delegate respondsToSelector:@selector(updateDirectionLocal:)]) {
            [self.delegate updateDirectionLocal:angle];
        }
    }
}


@end
