//
//  SleipnirMeasurementController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 05/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VaavudElectronicSDK/VEVaavudElectronicSDK.h>

@protocol SleipnirMeasurementControllerViewDelegate <NSObject>

- (void) viewSleipnirPluggedIn;
- (void) viewSleipnirPluggedOut;
- (void) viewAddSpeed:(NSNumber*)currentSpeed avgSpeed:(NSNumber*)averageSpeed maxSpeed:(NSNumber*)maxSpeed;
- (void) viewUpdateDirection:(NSNumber*)avgDirection;

@end

@interface SleipnirMeasurementController : NSObject <VaavudElectronicWindDelegate>

@property (nonatomic, weak) id<SleipnirMeasurementControllerViewDelegate> viewDelegate;

+ (SleipnirMeasurementController*) sharedInstance;

- (void) start;
- (NSTimeInterval) stop;

@end
