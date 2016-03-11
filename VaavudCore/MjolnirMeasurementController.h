//
//  vaavudCoreController.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VaavudMagneticFieldDataManager.h"
#import "VaavudDynamicsController.h"

@protocol WindMeasurementControllerDelegate <NSObject>

- (void)addSpeedMeasurement:(NSNumber *)currentSpeed avgSpeed:(NSNumber *)avgSpeed maxSpeed:(NSNumber *)maxSpeed;
- (void)changedValidity:(BOOL)isValid dynamicsIsValid:(BOOL)dynamicsIsValid;

@end

@interface MjolnirMeasurementController : NSObject <VaavudMagneticFieldDataManagerDelegate, VaavudDynamicsControllerDelegate>

@property (nonatomic, weak) id<WindMeasurementControllerDelegate> delegate;
@property (nonatomic) BOOL isValidCurrentStatus;
@property (nonatomic) BOOL dynamicsIsValid;
- (void)start;
- (NSTimeInterval)stop;

@end
