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
#import "VaavudMagneticFieldDataManager.h"

@interface VaavudCoreController () {
    
}

// public properties
//@property (nonatomic, strong) NSMutableArray *magneticFieldReadings
@property (nonatomic) float windSpeed;
@property (nonatomic) float windDirection;
@property (nonatomic) float windSpeedMax;

// private properties
//@property (nonatomic, strong) CMMotionManager *motionManager;
//@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) VaavudMagneticFieldDataManager *sharedMagneticFieldDataManager;


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

    // create reference to MagneticField Data Manager
    self.sharedMagneticFieldDataManager = [VaavudMagneticFieldDataManager sharedMagneticFieldDataManager];
    self.sharedMagneticFieldDataManager.delegate = self;
    [self.sharedMagneticFieldDataManager start];
        
    
}

- (void) stop
{
    
    [self.sharedMagneticFieldDataManager stop];
    
}


- (void) remove
{
    
}

- (void) magneticFieldValuesUpdated
{
    NSLog(@"Awesome Delegates work");
}


@end
