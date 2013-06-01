//
//  vaavudCoreController.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

@protocol VaavudCoreViewControllerDelegate   //define delegate protocol

- (void) windSpeedMeasurementsAreValid: (BOOL) valid;               //define delegate method to be implemented within another class

@end //end protocol

#import <Foundation/Foundation.h>
#import "VaavudMagneticFieldDataManager.h"
#import "vaavudDynamicsController.h"
#import "vaavudViewController.h"



@interface VaavudCoreController : NSObject <VaavudMagneticFieldDataManagerDelegate, vaavudDynamicsControllerDelegate>

- (id) init;
- (void) start;
- (void) stop;
- (void) remove;
- (NSNumber *) getAverage;
- (NSNumber *) getMax;
- (NSNumber *) getProgress;

@property (readonly, nonatomic, strong) NSNumber *setWindDirection;
@property (readonly, nonatomic) float currentWindSpeed;
@property (readonly, nonatomic) float currentWindDirection;
@property (readonly, nonatomic) float currentWindSpeedMax;
@property (readonly, nonatomic, strong) NSMutableArray *windSpeed;
@property (readonly, nonatomic, strong) NSMutableArray *isValid;
@property (readonly, nonatomic, strong) NSMutableArray *windSpeedTime;
@property (readonly, nonatomic, strong) NSMutableArray *windDirection;
@property (readonly, nonatomic, strong) NSDate *startTime;
@property (nonatomic) BOOL upsideDown;


@property (nonatomic) BOOL dynamicsIsValid;
@property (nonatomic) BOOL windDirectionIsConfirmed;
@property (nonatomic) BOOL FFTisValid;

@property (nonatomic, weak) id <VaavudCoreViewControllerDelegate> vaavudCoreControllerViewControllerDelegate;



@end
