//
//  LocationManager.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 01/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "LocationManager.h"
#import "SharedSingleton.h"
#import "Property+Util.h"

@interface LocationManager ()

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

// TODO: if location services disabled, regularly check to see if they become enabled
// TODO: wake up once in a while to get new fix
// TODO: implement iOS5 location method

@implementation LocationManager

SHARED_INSTANCE

- (id) init {
    self = [super init];
    
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        self.locationManager.distanceFilter = 500;
    }
    
    return self;
}

- (void) start {
    BOOL shouldPromptForLocation = NO;
    if (![Property getAsBoolean:@"hasPromptedForLocation"]) {
        shouldPromptForLocation = YES;
        [Property setAsBoolean:YES forKey:@"hasPromptedForLocation"];
        NSLog(@"Has not prompted for location");
    }
    
    if ([CLLocationManager locationServicesEnabled] || shouldPromptForLocation) {
        NSLog(@"Starting location updates");
        [self.locationManager startUpdatingLocation];
    }
}

// for iOS6
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
        
        NSLog(@"[LocationManager] Got latitude %+.6f, longitude %+.6f\n",
              location.coordinate.latitude,
              location.coordinate.longitude);
        
        self.latestLocation = location.coordinate;
        [self.locationManager stopUpdatingLocation];
    }
}

// for iOS5
- (void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
}

@end
