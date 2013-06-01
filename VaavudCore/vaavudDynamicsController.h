//
//  vaavudDynamicsController.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/19/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@protocol vaavudDynamicsControllerDelegate

- (void) DynamicsIsValid: (BOOL) validity;
- (void) newHeading: (NSNumber*) newHeading;

@end

@interface vaavudDynamicsController : NSObject <CLLocationManagerDelegate>

- (void) start;
- (void) stop;

@property (nonatomic) BOOL isValid;

@property (nonatomic, weak) id <vaavudDynamicsControllerDelegate> vaavudCoreController;

@end
