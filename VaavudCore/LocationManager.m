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

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSDate *latestLocationTimestamp;
@property (nonatomic) BOOL isStarted;

@end

@implementation LocationManager

SHARED_INSTANCE

+ (BOOL) isCoordinateValid:(CLLocationCoordinate2D) coordinate {
    return CLLocationCoordinate2DIsValid(coordinate) && !(coordinate.latitude == 0.0 && coordinate.longitude == 0.0);
}

- (id) init {
    self = [super init];
    
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.isStarted = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    }
    
    return self;
}

- (void) appWillResignActive:(NSNotification*) notification {
    NSLog(@"[LocationManager] appWillResignActive");
    [self stop];
}

- (void) appDidBecomeActive:(NSNotification*) notification {
    NSLog(@"[LocationManager] appDidBecomeActive");
    [self start];
}

-(void) appWillTerminate:(NSNotification*) notification {
    NSLog(@"[LocationManager] appWillTerminate");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

- (void) start {
    if (!self.isStarted) {
        BOOL shouldPromptForLocation = NO;
        if (![Property getAsBoolean:KEY_HAS_PROMPTED_FOR_LOCATION]) {
            shouldPromptForLocation = YES;
            [Property setAsBoolean:YES forKey:KEY_HAS_PROMPTED_FOR_LOCATION];
            NSLog(@"[LocationManager] Has not prompted for location");
        }
        
        if ([CLLocationManager locationServicesEnabled] || shouldPromptForLocation) {
            NSLog(@"[LocationManager] Starting location updates");
            [self.locationManager startUpdatingLocation];
            self.isStarted = YES;
        }
    }
}

- (void) stop {
    if (self.isStarted) {
        NSLog(@"[LocationManager] Stopping location updates");
        [self.locationManager stopUpdatingLocation];
        self.isStarted = NO;
    }
}

// for iOS6
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation* location = [locations lastObject];
    [self updateLocation:location];
}

// for iOS5
- (void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {

    [self updateLocation:newLocation];
}

- (void) updateLocation:(CLLocation*) location {
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0 /* seconds */) {
        
        //NSLog(@"[LocationManager] Got latitude %+.6f, longitude %+.6f\n", location.coordinate.latitude, location.coordinate.longitude);
        
        self.latestLocation = location.coordinate;
        self.latestLocationTimestamp = eventDate;
    }    
}

- (CLLocationCoordinate2D) latestLocation {
    NSTimeInterval howRecent = [self.latestLocationTimestamp timeIntervalSinceNow];
    if (abs(howRecent) < 300.0 /* seconds */) {
        //NSLog(@"[LocationManager] returning latest location: latitude %+.6f, longitude %+.6f\n", _latestLocation.latitude, _latestLocation.longitude);
        return _latestLocation;
    }
    //NSLog(@"[LocationManager] latest location too old, returning invalid");
    return kCLLocationCoordinate2DInvalid;
}

@end
