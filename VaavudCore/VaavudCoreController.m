//
//  vaavudCoreController.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "VaavudCoreController.h"
#import <CoreMotion/CoreMotion.h>
#import "VCMagneticFieldReading.h"

@interface VaavudCoreController () {
    
    @private
    NSNumber *startTime;
}

// public properties
@property (nonatomic, strong) NSMutableArray *magneticFieldReadings;
@property (nonatomic) float windSpeed;
@property (nonatomic) float windDirection;
@property (nonatomic) float windSpeedMax;

// private properties
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *operationQueue;


- (void) startMagneticFieldSensor;


@end

@implementation VaavudCoreController {
   
}


// Public methods

- (id) init
{
    self = [super init];
    
    if (self)
    {
        // Do initializing
        
    }
    
    return self;
    
}

- (void) start
{

    // create mutable array that will hold magnetic field data
    self.magneticFieldReadings = [[NSMutableArray alloc] init];
    startTime = [[NSNumber alloc] initWithDouble: CACurrentMediaTime()];
    [self startMagneticFieldSensor];
    
    
}

- (void) stop
{
    [self.motionManager stopMagnetometerUpdates];
    self.motionManager = nil;
    
}


- (void) remove
{
    
}


// Private methods
- (void) startMagneticFieldSensor
{
 
       
    self.motionManager = [[CMMotionManager alloc] init];
    
    if (self.motionManager.magnetometerAvailable) {
        self.motionManager.magnetometerUpdateInterval = 1.0/preferedSampleFrequency;
        self.operationQueue = [NSOperationQueue currentQueue];
        [self.motionManager startMagnetometerUpdatesToQueue:self.operationQueue withHandler:^(CMMagnetometerData *magnetometerData, NSError *error) {
            CMMagneticField magneticField = magnetometerData.magneticField;
            
            double timeSinceStart = CACurrentMediaTime() - startTime.doubleValue;
            
            VCMagneticFieldReading *magneticFieldReading = [[VCMagneticFieldReading alloc] initWithTime: timeSinceStart timeAndX:magneticField.x andY:magneticField.y andZ:magneticField.z];
                
            [self.magneticFieldReadings addObject: magneticFieldReading];
            
            
            // 
//            [self updateDisplay:field];
//            
//            if (isLogging) {
//                double time = CACurrentMediaTime();
//                
//                if (counter == 0)
//                    startTime = time;
//                [self logSet:field andTime:time];
//            }
            
            NSLog( @"magnetic field reading time: %f   x: %f", magneticFieldReading.time, magneticFieldReading.x);
            
        }];
        
    }  else {
        NSLog(@"No MagnetometerAvailable on device.");
    }

    
}


@end
