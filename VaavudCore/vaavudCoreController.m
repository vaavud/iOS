//
//  vaavudCoreController.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "vaavudCoreController.h"

@interface vaavudCoreController ()

    @property (nonatomic, strong) NSMutableArray *magneticFieldReadings;
    @property (nonatomic) float windSpeed;
    @property (nonatomic) float windDirection;
    @property (nonatomic) float windSpeedMax;


@end

@implementation vaavudCoreController

@synthesize magneticFieldReadings;
@synthesize windSpeed;
@synthesize windDirection;
@synthesize windSpeedMax;

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
    
}

- (void) stop
{
    
}


@end
