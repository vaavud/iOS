//
//  VaavudMagneticFieldDataManager.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/9/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "VaavudMagneticFieldDataManager.h"
#import <CoreMotion/CoreMotion.h>

@interface VaavudMagneticFieldDataManager () 

// public properties - generate setter
@property (nonatomic, strong) NSMutableArray *magneticFieldReadingsTime;
@property (nonatomic, strong) NSMutableArray *magneticFieldReadingsx;
@property (nonatomic, strong) NSMutableArray *magneticFieldReadingsy;
@property (nonatomic, strong) NSMutableArray *magneticFieldReadingsz;

// private properties
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *operationQueue;


- (void) startMagneticFieldSensor;

@end


@implementation VaavudMagneticFieldDataManager {
    
    NSNumber *startTime;
    
}

static VaavudMagneticFieldDataManager *sharedMagneticFieldDataManager = nil;

+ (VaavudMagneticFieldDataManager*) sharedMagneticFieldDataManager
{
    if (sharedMagneticFieldDataManager == nil) {
        sharedMagneticFieldDataManager = [[super allocWithZone:NULL] init];
    }
    return sharedMagneticFieldDataManager;
}


- (void) start
{
    
    // create mutable array that will hold magnetic field data
    self.magneticFieldReadingsTime = [[NSMutableArray alloc] init];
    self.magneticFieldReadingsx = [[NSMutableArray alloc] init];
    self.magneticFieldReadingsy = [[NSMutableArray alloc] init];
    self.magneticFieldReadingsz = [[NSMutableArray alloc] init];

    
    startTime = [[NSNumber alloc] initWithDouble: CACurrentMediaTime()];
    
    [self startMagneticFieldSensor];
    
    
}

- (void) stop
{
    [self.motionManager stopMagnetometerUpdates];
    self.motionManager = nil;
    
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
            
            [self.magneticFieldReadingsTime addObject: [NSNumber numberWithDouble: timeSinceStart]];
            [self.magneticFieldReadingsx addObject: [NSNumber numberWithDouble: magneticField.x]];
            [self.magneticFieldReadingsy addObject: [NSNumber numberWithDouble: magneticField.y]];
            [self.magneticFieldReadingsz addObject: [NSNumber numberWithDouble: magneticField.z]];

            [self.delegate magneticFieldValuesUpdated]; // SEND Notification to delegate that a new measurement has been recived
            
        }];
        
    }  else {
        NSLog(@"No MagnetometerAvailable on device.");
    }
    
    
}



@end