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
#import "WindMeasurementController.h"

@interface MjolnirMeasurementController : WindMeasurementController <VaavudMagneticFieldDataManagerDelegate, VaavudDynamicsControllerDelegate>

@property (nonatomic) BOOL isValidCurrentStatus;
@property (nonatomic) BOOL dynamicsIsValid;

@end
