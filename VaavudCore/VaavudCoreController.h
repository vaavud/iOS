//
//  vaavudCoreController.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

@protocol VaavudCoreViewControllerDelegate

- (void) windSpeedMeasurementsAreValid:(BOOL)valid;
- (void) measuringStoppedByModel;

@end

#import <Foundation/Foundation.h>
#import "VaavudMagneticFieldDataManager.h"
#import "vaavudDynamicsController.h"
#import "vaavudViewController.h"

@interface VaavudCoreController : NSObject <VaavudMagneticFieldDataManagerDelegate, vaavudDynamicsControllerDelegate>

- (id) init;
- (void) start;
- (NSTimeInterval) stop;
- (void) remove;
- (NSNumber *) getAverage;
- (NSNumber *) getMax;
- (NSNumber *) getProgress;

@property (readonly, nonatomic, strong) NSNumber *setWindDirection;
@property (readonly, nonatomic, strong) NSMutableArray *windSpeed;
@property (readonly, nonatomic, strong) NSMutableArray *isValid;
@property (readonly, nonatomic, strong) NSMutableArray *windSpeedTime;
@property (readonly, nonatomic, strong) NSMutableArray *windDirection;
@property (readonly, nonatomic, strong) NSDate *startTime;
@property (nonatomic) BOOL upsideDown;
@property (readonly, nonatomic) int fftLength;
@property (readonly, nonatomic) int fftDataLength;

@property (nonatomic) BOOL dynamicsIsValid;
@property (nonatomic) BOOL windDirectionIsConfirmed;
@property (nonatomic) BOOL FFTisValid;

@property (nonatomic, weak) id <VaavudCoreViewControllerDelegate> vaavudCoreControllerViewControllerDelegate;

@end
