//
//  LocationManager.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 01/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic) CLLocationCoordinate2D latestLocation;
@property (nonatomic, strong) NSNumber *latestHeading;

+ (LocationManager *)sharedInstance;
+ (BOOL)isCoordinateValid:(CLLocationCoordinate2D)coordinate;

- (void)start;
- (void)startIfEnabled;

@end
