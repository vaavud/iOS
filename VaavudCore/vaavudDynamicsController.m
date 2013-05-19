//
//  vaavudDynamicsController.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/19/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//
//  Check if abs(acceleration) & device orientation & gyroscope is below theshold values
//

#import "vaavudDynamicsController.h"
#import <CoreMotion/CoreMotion.h>


@interface vaavudDynamicsController ()
    @property (nonatomic, strong) CMMotionManager *motionManager;
    @property (nonatomic, strong) NSOperationQueue *operationQueue;
    @property (nonatomic) BOOL accelerationIsValid;
    @property (nonatomic) BOOL orientationIsValid;
    @property (nonatomic) BOOL angularVeclocityIsValid;
    @property (nonatomic) BOOL wasValid;

    - (void) updateValidity;

@end

@implementation vaavudDynamicsController

- (id) init
{
    self = [super init];
    
    if (self)
    {
        // Do initializing
//        self.FFTEngine = [[vaavudFFT alloc] initFFTLength:FFTLength];
        
        self.accelerationIsValid = YES;
        self.angularVeclocityIsValid = YES;
        self.orientationIsValid = YES;
        
    }
    
    return self;
    
}


- (void) updateValidity
{
    if (self.accelerationIsValid && self.orientationIsValid && self.angularVeclocityIsValid)
        self.isValid = YES;
    else
        self.isValid = NO;
    
    
    if (!self.wasValid == self.isValid) {
        [self.delegate DynamicsIsValid:self.isValid];
    }
    
    self.wasValid = self.isValid;
}



- (void) start
{
    self.motionManager = [[CMMotionManager alloc] init];
    
    if(self.motionManager.accelerometerAvailable) {
        self.motionManager.accelerometerUpdateInterval = 1.0/accAndGyroSampleFrequency;
        self.operationQueue = [NSOperationQueue currentQueue];
        
        [self.motionManager startAccelerometerUpdatesToQueue:self.operationQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            
            double acceleration = fabs( sqrt( pow(accelerometerData.acceleration.x, 2) + pow(accelerometerData.acceleration.y,2) + pow(accelerometerData.acceleration.z,2) ) - 1.0 );
            
                                       if (acceleration > accelerationMaxForValid ) {
                                           self.accelerationIsValid = NO;
                                           NSLog(@"Acceleration is too big with value %f", acceleration);
                                       }
                                       else {
                                            self.accelerationIsValid = YES;
                                       }
           
            
            [self updateValidity];
            
        }];
        
        
        
    }
    
    
    
    
//    if (self.motionManager.magnetometerAvailable) {
//        self.motionManager.magnetometerUpdateInterval = 1.0/accAndGyroSampleFrequency;
//        self.operationQueue = [NSOperationQueue currentQueue];
//        [self.motionManager startMagnetometerUpdatesToQueue:self.operationQueue withHandler:^(CMMagnetometerData *magnetometerData, NSError *error) {
//            CMMagneticField magneticField = magnetometerData.magneticField;
//            
//            double timeSinceStart = CACurrentMediaTime() - startTime.doubleValue;
//            
//            //            VCMagneticFieldReading *magneticFieldReading = [[VCMagneticFieldReading alloc] initWithTime: timeSinceStart timeAndX:magneticField.x andY:magneticField.y andZ:magneticField.z];
//            [self.magneticFieldReadingsTime addObject: [NSNumber numberWithDouble: timeSinceStart]];
//            [self.magneticFieldReadingsx addObject: [NSNumber numberWithDouble: magneticField.x]];
//            [self.magneticFieldReadingsy addObject: [NSNumber numberWithDouble: magneticField.y]];
//            [self.magneticFieldReadingsz addObject: [NSNumber numberWithDouble: magneticField.z]];
//            
//            
//            //            [self.magneticFieldReadings addObject: magneticFieldReading];
//            
//            [self.delegate magneticFieldValuesUpdated]; // SEND Notification to delegate that a new measurement has been recived
//            
//            
//            //            NSLog( @"magnetic field reading time: %f   x: %f", magneticFieldReading.time, magneticFieldReading.x);
//            
//        }];
//        
//    }  else {
//        NSLog(@"No MagnetometerAvailable on device.");
//    }


}

- (void) stop
{
    
}

@end
