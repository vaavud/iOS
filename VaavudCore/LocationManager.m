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
@property (nonatomic) BOOL shouldPromptForPermission;

@end

@implementation LocationManager

SHARED_INSTANCE

+ (BOOL)isCoordinateValid:(CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DIsValid(coordinate) && !(coordinate.latitude == 0.0 && coordinate.longitude == 0.0);
}

- (id)init {
    self = [super init];
    
    if (self) {
        self.isStarted = NO;
        self.shouldPromptForPermission = NO;
    }
    
    return self;
}

- (void)appWillResignActive:(NSNotification *)notification {
    //NSLog(@"[LocationManager] appWillResignActive");
    [self stop];
}

- (void)appDidBecomeActive:(NSNotification *)notification {
    //NSLog(@"[LocationManager] appDidBecomeActive");
    [self doStart];
}

- (void)appWillTerminate:(NSNotification *)notification {
    if (LOG_LOCATION) NSLog(@"[LocationManager] appWillTerminate");
    if (self.isStarted) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    }
}

- (void)startIfEnabled {
    self.shouldPromptForPermission = NO;
    [self doStart];
}

- (void)start {
    self.shouldPromptForPermission = YES;
    [self doStart];
}

- (void)doStart {
    if (!self.isStarted) {
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        
      if (LOG_LOCATION) NSLog(@"[LocationManager] Authorization status is %u", authorizationStatus);
        
        if (authorizationStatus == kCLAuthorizationStatusRestricted || authorizationStatus == kCLAuthorizationStatusDenied) {
            self.latestLocation = CLLocationCoordinate2DMake(0, 0);
            return;
        }

        if (!self.locationManager) {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            self.locationManager.distanceFilter = kCLDistanceFilterNone;
        }
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            if (authorizationStatus == kCLAuthorizationStatusNotDetermined) {
                if (self.shouldPromptForPermission) {
                  if (LOG_LOCATION) NSLog(@"[LocationManager] Request when-in-use location authorization");
                    [self.locationManager requestWhenInUseAuthorization];
                }
            }
            else if ([CLLocationManager locationServicesEnabled]) {
                [self startUpdating];
            }
        }
        else if ([CLLocationManager locationServicesEnabled] &&
                 (authorizationStatus != kCLAuthorizationStatusNotDetermined || self.shouldPromptForPermission)) {
            
            [self startUpdating];
        }
    }
}

- (void)startUpdating {
  if (LOG_LOCATION) NSLog(@"[LocationManager] Starting location updates");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];

    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];
    self.isStarted = YES;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  if (LOG_LOCATION) NSLog(@"[LocationManager] Changed authorization status to %u", status);
    
    if (status != kCLAuthorizationStatusRestricted && status != kCLAuthorizationStatusDenied && status != kCLAuthorizationStatusNotDetermined) {
        [self startUpdating];
    }
}

- (void)stop {
    if (self.isStarted) {
      if (LOG_LOCATION) NSLog(@"[LocationManager] Stopping location updates");
        [self.locationManager stopUpdatingLocation];
        [self.locationManager stopUpdatingHeading];
        self.latestHeading = nil;
        self.isStarted = NO;
    }
}

// for iOS6
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    [self updateLocation:location];
}

// for iOS5
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [self updateLocation:newLocation];
}

- (void)updateLocation:(CLLocation *)location {
    NSDate *eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (fabs(howRecent) < 15.0 /* seconds */) {
        //NSLog(@"[LocationManager] Got latitude %+.6f, longitude %+.6f\n", location.coordinate.latitude, location.coordinate.longitude);
        
        self.latestLocation = location.coordinate;
        self.latestLocationTimestamp = eventDate;
    }    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    self.latestHeading = [NSNumber numberWithDouble:newHeading.trueHeading];
}

- (CLLocationCoordinate2D)latestLocation {
    NSTimeInterval howRecent = [self.latestLocationTimestamp timeIntervalSinceNow];
    if (fabs(howRecent) < 60.0 /* seconds */) {
        //NSLog(@"[LocationManager] returning latest location: latitude %+.6f, longitude %+.6f\n", _latestLocation.latitude, _latestLocation.longitude);
        return _latestLocation;
    }
    //NSLog(@"[LocationManager] latest location too old, returning invalid");
    return kCLLocationCoordinate2DInvalid;
}

@end
