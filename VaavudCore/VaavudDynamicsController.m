//
//  VaavudDynamicsController.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/19/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//
//  Check if abs(acceleration) & device orientation & gyroscope is below theshold values
//

#import "VaavudDynamicsController.h"
#import <CoreMotion/CoreMotion.h>

@interface VaavudDynamicsController ()

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic) BOOL accelerationIsValid;
@property (nonatomic) BOOL orientationIsValid;
@property (nonatomic) BOOL angularVeclocityIsValid;

@property (nonatomic, strong) CLLocationManager *locationManager;

- (void)updateValidity;

@end

@implementation VaavudDynamicsController

- (id)init {
    self = [super init];
    
    if (self) {
        self.accelerationIsValid = YES;
        self.angularVeclocityIsValid = YES;
        self.orientationIsValid = YES;
    }
    
    return self;
}

- (void)updateValidity {
    self.isValid = self.accelerationIsValid && self.orientationIsValid && self.angularVeclocityIsValid;
    
    [self.vaavudCoreController dynamicsIsValid:self.isValid];
}

- (void)start {
    self.motionManager = [[CMMotionManager alloc] init];
    
    if (self.motionManager.deviceMotionAvailable) {
        self.motionManager.deviceMotionUpdateInterval = 1.0/accAndGyroSampleFrequency;
        
        if (!self.operationQueue) {
            self.operationQueue = [NSOperationQueue currentQueue];
        }
        
        [self.motionManager startDeviceMotionUpdatesToQueue:self.operationQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {
            
            // Orientation
            double deviceDeviationFromVertical =  M_PI/2 - fabs(motion.attitude.pitch);
            
            if (deviceDeviationFromVertical > orientationDeviationMaxForValid) {
                self.orientationIsValid = NO;
                
                // TODO: reinsert
                //NSLog(@"Orientation deviation from vertical is too big with value %f", deviceDeviationFromVertical);
            }
            else {
                self.orientationIsValid = YES;
            }
            
            // angular velocity
            double angularVelocity = fabs(sqrt(pow(motion.rotationRate.x, 2) + pow(motion.rotationRate.x, 2) + pow(motion.rotationRate.x, 2)));
            
            if (angularVelocity > angularVelocityMaxForValid) {
                self.angularVeclocityIsValid = NO;
                // TODO: reinsert
                //NSLog(@"Angular velocity is too big with value %f ", angularVelocity);
            }
            else {
                self.angularVeclocityIsValid = YES;
            }

            // acceleration
            double acceleration = fabs(sqrt(pow(motion.userAcceleration.x, 2) + pow(motion.userAcceleration.y, 2) + pow(motion.userAcceleration.z, 2)));
            
            if (acceleration > accelerationMaxForValid) {
                self.accelerationIsValid = NO;
                // TODO: reinsert
                //NSLog(@"Acceleration is too big with value %f", acceleration);
            }
            else {
                self.accelerationIsValid = YES;
            }
            
            [self updateValidity];
        }];
        
    }
    
    if ([CLLocationManager headingAvailable]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.headingFilter = 1;
        [self.locationManager startUpdatingHeading];
    }
    else {
        NSLog(@"No heading avaliable!!!");
    }
}

- (void)stop {
    [self.motionManager stopDeviceMotionUpdates];
    self.motionManager = nil;
    self.operationQueue = nil;
    [self.locationManager stopUpdatingHeading];
}

// Heading

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    [self.vaavudCoreController newHeading: [NSNumber numberWithDouble: newHeading.trueHeading]];
//    NSLog(@"heading accuracy: %f", newHeading.headingAccuracy);
}

@end
