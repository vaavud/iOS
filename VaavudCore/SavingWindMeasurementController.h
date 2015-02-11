//
//  SavingWindMeasurementController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "WindMeasurementController.h"
#import "MeasurementSession+Util.h"

@interface SavingWindMeasurementController : WindMeasurementController <WindMeasurementControllerDelegate>

@property (nonatomic) BOOL lookupTemperature;
@property (nonatomic, strong) NSNumber *privacy;

+ (SavingWindMeasurementController *)sharedInstance;

- (void)setHardwareController:(WindMeasurementController *)controller;
- (void)clearHardwareController;
- (MeasurementSession *)getLatestMeasurementSession;

@end
