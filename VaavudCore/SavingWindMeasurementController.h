//
//  SavingWindMeasurementController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "WindMeasurementController.h"

@interface SavingWindMeasurementController : WindMeasurementController <WindMeasurementControllerDelegate>

@property (nonatomic, weak) id<WindMeasurementControllerDelegate> delegate;
@property (nonatomic) BOOL lookupTemperature;

+ (SavingWindMeasurementController*) sharedInstance;

- (void) setHardwareController:(WindMeasurementController*)controller;
- (void) clearHardwareController;

@end
