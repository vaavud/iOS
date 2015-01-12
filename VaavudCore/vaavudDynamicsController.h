//
//  vaavudDynamicsController.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/19/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol VaavudDynamicsControllerDelegate

- (void)dynamicsIsValid:(BOOL)validity;
- (void)newHeading:(NSNumber *)newHeading;

@end

@interface VaavudDynamicsController : NSObject <CLLocationManagerDelegate>

- (void)start;
- (void)stop;

@property (nonatomic) BOOL isValid;

@property (nonatomic, weak) id<VaavudDynamicsControllerDelegate> vaavudCoreController;

@end
