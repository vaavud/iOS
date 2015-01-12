//
//  SleipnirMeasurementController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 05/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VaavudElectronicSDK/VEVaavudElectronicSDK.h>
#import "WindMeasurementController.h"

@interface SleipnirMeasurementController : WindMeasurementController <VaavudElectronicWindDelegate>

@property (nonatomic) BOOL isDeviceConnected;

+ (SleipnirMeasurementController *)sharedInstance;

@end
