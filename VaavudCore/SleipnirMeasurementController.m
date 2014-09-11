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

- (id) init {
    self = [super init];
    
    if (self) {
        [self resetMeasurementData];
        VEVaavudElectronicSDK *sdk = [VEVaavudElectronicSDK sharedVaavudElectronic];
        self.isDeviceConnected = ([sdk vaavudElectronicConnectionStatus] == VaavudElectronicConnectionStatusConnected);
        [sdk addListener:self];
    }
    
    return self;
}

- (void) resetMeasurementData {

    self.isStarted = NO;
    self.accumulatedSpeed = 0.0;
    self.maxSpeed = 0.0;
    self.numberOfSpeedSamples = 0;
    self.averageSpeed = nil;
    self.direction = nil;
}

- (enum WindMeterDeviceType) windMeterDeviceType {
    return SleipnirWindMeterDeviceType;
}

- (void) start {

    [self resetMeasurementData];
    self.isStarted = YES;
    self.startTime = [NSDate date];
    [[VEVaavudElectronicSDK sharedVaavudElectronic] start];
}

- (NSTimeInterval) stop {
    
    if (!self.isStarted) {
        // don't do anything if we're already stopped
        return 0.0;
    }
    
    self.isStarted = NO;
    [[VEVaavudElectronicSDK sharedVaavudElectronic] stop];
    NSTimeInterval durationSeconds = [[NSDate date] timeIntervalSinceDate:self.startTime];
    return durationSeconds;
}

- (void) devicePlugedInChecking {
    NSLog(@"[SleipnirMeasurementController] devicePlugedInChecking");
}

- (void) notVaavudPlugedIn {
    NSLog(@"[SleipnirMeasurementController] notVaavudPlugedIn");
}

- (void) vaavudPlugedIn {
    
    NSLog(@"[SleipnirMeasurementController] vaavudPlugedIn");
    self.isDeviceConnected = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceConnected:)]) {
        [self.delegate deviceConnected:SleipnirWindMeterDeviceType];
    }
}

- (void) deviceWasUnpluged {
    
    NSLog(@"[SleipnirMeasurementController] deviceWasUnpluged");
    self.isDeviceConnected = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceDisconnected:)]) {
        [self.delegate deviceDisconnected:SleipnirWindMeterDeviceType];
    }
}

- (void) newSpeed:(NSNumber*)speed {
    
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

- (void) newWindDirection:(NSNumber*)windDirection {
    
    // make sure we don't do anything with new data after the user has clicked stop
    if (self.isStarted && windDirection) {

        self.direction = windDirection;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(updateDirection:)]) {
            [self.delegate updateDirection:self.direction];
        }
    }
}

@end
