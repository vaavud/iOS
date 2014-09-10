//
//  SleipnirMeasurementController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 05/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VaavudElectronicSDK/VEVaavudElectronicSDK.h>

@protocol SleipnirMeasurementControllerDelegate <NSObject>

- (void) sleipnirPluggedIn;
- (void) sleipnirPluggedOut;
- (void) addSpeedMeasurement:(NSNumber*)currentSpeed avgSpeed:(NSNumber*)avgSpeed maxSpeed:(NSNumber*)maxSpeed;
- (void) updateDirection:(NSNumber*)direction;

@end

@interface SleipnirMeasurementController : NSObject <VaavudElectronicWindDelegate>

@property (nonatomic, weak) id<SleipnirMeasurementControllerDelegate> delegate;

+ (SleipnirMeasurementController*) sharedInstance;

- (void) start;
- (NSTimeInterval) stop;

@end
