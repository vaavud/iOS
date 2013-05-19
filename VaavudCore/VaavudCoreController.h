//
//  vaavudCoreController.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VaavudMagneticFieldDataManager.h"
#import "vaavudDynamicsController.h"


@interface VaavudCoreController : NSObject <VaavudMagneticFieldDataManagerDelegate, vaavudDynamicsControllerDelegate>

- (id) init;
- (void) start;
- (void) stop;
- (void) remove;
- (void) magneticFieldValuesUpdated;

//@property (readonly, nonatomic, strong) NSMutableArray *magneticFieldReadings;
@property (readonly, nonatomic) float currentWindSpeed;
@property (readonly, nonatomic) float currentWindDirection;
@property (readonly, nonatomic) float currentWindSpeedMax;
@property (readonly, nonatomic, strong) NSMutableArray *windSpeed;
@property (readonly, nonatomic, strong) NSMutableArray *isValid;
@property (readonly, nonatomic, strong) NSMutableArray *time;





@end
