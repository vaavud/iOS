//
//  SavingWindMeasurementController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#define SAVE_MINIMUM_INTERVAL_SECONDS 1.0

#import "SavingWindMeasurementController.h"
#import "SharedSingleton.h"
#import "LocationManager.h"
#import "ServerUploadManager.h"
#import "Property+Util.h"
#import "UUIDUtil.h"
#import "AppDelegate.h"
#import "MeasurementPoint+Util.h"

@interface SavingWindMeasurementController ()

@property (nonatomic) BOOL hasBeenStopped;
@property (nonatomic) BOOL wasValid;
@property (nonatomic, weak) WindMeasurementController *controller;
@property (nonatomic, strong) NSString *measurementSessionUuid;
@property (nonatomic, strong) NSNumber *currentAvgSpeed;
@property (nonatomic, strong) NSNumber *currentMaxSpeed;
@property (nonatomic, strong) NSNumber *currentDirection;
@property (nonatomic, strong) NSDate *lastSaveTime;
@property (nonatomic, strong) NSTimer *temperatureLookupTimer;

@end

@implementation SavingWindMeasurementController

SHARED_INSTANCE

- (void)setHardwareController:(WindMeasurementController *)controller {
    self.controller = controller;
    self.controller.delegate = self;
}

- (void)clearHardwareController {
    self.controller = nil;
}

- (void)start {
    if (self.controller) {
        self.hasBeenStopped = NO;
        self.wasValid = YES;
        self.lastSaveTime = nil;
        self.currentAvgSpeed = nil;
        self.currentMaxSpeed = nil;
        self.currentDirection = nil;

        NSArray *measuringMeasurementSessions = [MeasurementSession MR_findByAttribute:@"measuring" withValue:[NSNumber numberWithBool:YES]];
        if (measuringMeasurementSessions && [measuringMeasurementSessions count] > 0) {
            for (MeasurementSession *measurementSession in measuringMeasurementSessions) {
                measurementSession.measuring = [NSNumber numberWithBool:NO];
            }
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
        }
        
        if (!self.privacy) {
            self.privacy = [NSNumber numberWithInt:1];
        }
        
        // create new MeasurementSession and save it in the database
        MeasurementSession *measurementSession = [MeasurementSession MR_createEntity];
        measurementSession.uuid = [UUIDUtil generateUUID];
        measurementSession.device = [Property getAsString:KEY_DEVICE_UUID];
        measurementSession.windMeter = [NSNumber numberWithInteger:[self.controller windMeterDeviceType]];
        measurementSession.startTime = [NSDate date];
        measurementSession.timezoneOffset = [NSNumber numberWithInt:(int) [[NSTimeZone localTimeZone] secondsFromGMTForDate:measurementSession.startTime]];
        measurementSession.endTime = measurementSession.startTime;
        measurementSession.measuring = [NSNumber numberWithBool:YES];
        measurementSession.uploaded = [NSNumber numberWithBool:NO];
        measurementSession.startIndex = [NSNumber numberWithInt:0];
        measurementSession.privacy = self.privacy;
        [self updateMeasurementSessionLocation:measurementSession];
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.xCallbackSuccess && appDelegate.xCallbackSuccess != nil && appDelegate.xCallbackSuccess != (id)[NSNull null] && [appDelegate.xCallbackSuccess length] > 0) {
            NSArray *components = [appDelegate.xCallbackSuccess componentsSeparatedByString:@":"];
            if ([components count] > 0) {
                measurementSession.source = [components objectAtIndex:0];
            }
            else {
                measurementSession.source = appDelegate.xCallbackSuccess;
            }
        }
        else {
            measurementSession.source = @"vaavud";
        }
        
        self.measurementSessionUuid = measurementSession.uuid;
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (success) {
                [[ServerUploadManager sharedInstance] triggerUpload];
            }
        }];
        
        // lookup temperature
        
        if (self.lookupTemperature) {
            self.temperatureLookupTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(initiateTemperatureLookup) userInfo:nil repeats:YES];
        }

        [self.controller start];
    }
}

- (NSTimeInterval)stop {
    if (self.hasBeenStopped) {
        return 0.0;
    }
    self.hasBeenStopped = YES;

    if (self.temperatureLookupTimer) {
        [self.temperatureLookupTimer invalidate];
        self.temperatureLookupTimer = nil;
    }

    if (self.controller) {
        [self.controller stop];
    }
    
    NSTimeInterval durationSeconds = 0.0;
    
    // note: active measurement session may become nil if it is deleted from history while measuring
    MeasurementSession *measurementSession = [self getLatestMeasurementSession];
    if (measurementSession && measurementSession.measuring.boolValue) {
        measurementSession.measuring = @NO;
        measurementSession.endTime = [NSDate date];
        
        // make sure the DB reflects whats currently shown in the UI
        measurementSession.windSpeedAvg = self.currentAvgSpeed;
        measurementSession.windSpeedMax = self.currentMaxSpeed;
        measurementSession.windDirection = self.currentDirection;

        if (measurementSession.startTime && measurementSession.endTime) {
            durationSeconds = [measurementSession.endTime timeIntervalSinceDate:measurementSession.startTime];
        }
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error){
            if (success) {
                if (self.delegate) {
                    // this is just to update the UI label values so they reflect what was saved
                    [self.delegate addSpeedMeasurement:nil avgSpeed:measurementSession.windSpeedAvg maxSpeed:measurementSession.windSpeedMax];
                }
                [[ServerUploadManager sharedInstance] triggerUpload];
            }
        }];
    }
    
    return durationSeconds;
}

- (enum WindMeterDeviceType)windMeterDeviceType {
    if (self.controller) {
        return [self.controller windMeterDeviceType];
    }
    return UnknownWindMeterDeviceType;
}

- (MeasurementSession *)getLatestMeasurementSession {
    if (self.measurementSessionUuid) {
        return [MeasurementSession MR_findFirstByAttribute:@"uuid" withValue:self.measurementSessionUuid];
    }
    else {
        return nil;
    }
}

#pragma mark WindMeasurementControllerDelegate methods

- (void)addSpeedMeasurement:(NSNumber *)currentSpeed avgSpeed:(NSNumber *)avgSpeed maxSpeed:(NSNumber *)maxSpeed {
    
    MeasurementSession *measurementSession = [self getLatestMeasurementSession];
    if (!measurementSession || ![measurementSession.measuring boolValue]) {
        // Measurement session became nil or "measuring" became NO during measuring which is most likely due to it being
        // deleted from the history or ServerUploadManager toggled the measuring flag to NO after a long period of
        // inactivity.
        [self stop];
        if (self.delegate && [self.delegate respondsToSelector:@selector(measuringStoppedByModel)]) {
            [self.delegate measuringStoppedByModel];
        }
        return;
    }

    //NSLog(@"[SavingWindMeasurementController] Adding measurement, current=%@, avg=%@, max=%@", currentSpeed, avgSpeed, maxSpeed);
    
    // only save if more than SAVE_MINIMUM_INTERVAL_SECONDS has passed since we last saved a point
    
    NSDate *now = [NSDate date];
    if (!self.lastSaveTime || ([now timeIntervalSinceDate:self.lastSaveTime] >= SAVE_MINIMUM_INTERVAL_SECONDS)) {
        self.lastSaveTime = now;
        
        // update location to the latest position (we might not have a fix when pressing start)
        [self updateMeasurementSessionLocation:measurementSession];
        
        // always update measurement session's endtime and summary info
        measurementSession.endTime = [NSDate date];
        measurementSession.windSpeedAvg = avgSpeed;
        measurementSession.windSpeedMax = maxSpeed;
        measurementSession.windDirection = self.currentDirection;
        
        // add MeasurementPoint and save to database
        MeasurementPoint *measurementPoint = [MeasurementPoint MR_createEntity];
        measurementPoint.session = measurementSession;
        measurementPoint.time = [NSDate date];
        measurementPoint.windSpeed = currentSpeed;
        measurementPoint.windDirection = self.currentDirection;
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
    }

    self.currentAvgSpeed = avgSpeed;
    self.currentMaxSpeed = maxSpeed;
    
    if (self.delegate) {
        [self.delegate addSpeedMeasurement:currentSpeed avgSpeed:avgSpeed maxSpeed:maxSpeed];
    }
}

- (void)updateDirection:(NSNumber *)direction {
    if (direction) {
        self.currentDirection = direction;
        
        if ([self.delegate respondsToSelector:@selector(updateDirection:)]) {
            [self.delegate updateDirection:direction];
        }
    }
}

- (void)updateDirectionLocal:(NSNumber *)direction {
    if (direction) {
        if ([self.delegate respondsToSelector:@selector(updateDirectionLocal:)]) {
            [self.delegate updateDirectionLocal:direction];
        }
    }
}

- (void)changedValidity:(BOOL)isValid dynamicsIsValid:(BOOL)dynamicsIsValid {
    MeasurementSession *measurementSession = [self getLatestMeasurementSession];
    if (!isValid && self.wasValid && measurementSession && [measurementSession.measuring boolValue]) {
        // current measurement is not valid, but the previous one was, so add a point indicating that there is a "hole" in the data
        
        MeasurementPoint *measurementPoint = [MeasurementPoint MR_createEntity];
        measurementPoint.session = measurementSession;
        measurementPoint.time = [NSDate date];
        measurementPoint.windSpeed = nil;
        measurementPoint.windDirection = nil;
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
    }
    
    self.wasValid = isValid;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(changedValidity:dynamicsIsValid:)]) {
        [self.delegate changedValidity:isValid dynamicsIsValid:dynamicsIsValid];
    }
}

- (void)deviceAvailabilityChanged:(enum WindMeterDeviceType)device andAvailability:(BOOL)available {
    if ([self.delegate respondsToSelector:@selector(deviceAvailabilityChanged:andAvailability:)]) {
        [self.delegate deviceAvailabilityChanged:device andAvailability:available];
    }
}

- (void)deviceConnected:(enum WindMeterDeviceType)device {
    if ([self.delegate respondsToSelector:@selector(deviceConnected:)]) {
        [self.delegate deviceConnected:device];
    }
}

- (void)deviceDisconnected:(enum WindMeterDeviceType)device {
    if ([self.delegate respondsToSelector:@selector(deviceDisconnected:)]) {
        [self.delegate deviceDisconnected:device];
    }
}

- (void)measuringStoppedByModel {
    if ([self.delegate respondsToSelector:@selector(measuringStoppedByModel)]) {
        [self.delegate measuringStoppedByModel];
    }
}

#pragma mark Location methods

- (void)updateMeasurementSessionLocation:(MeasurementSession *)measurementSession {
    if (measurementSession && [measurementSession.measuring boolValue]) {

        CLLocationCoordinate2D latestLocation = [LocationManager sharedInstance].latestLocation;
        if ([LocationManager isCoordinateValid:latestLocation]) {
            
            //NSLog(@"[SavingWindMeasurementController] Valid location (%+.6f, %+.6f)", latestLocation.latitude, latestLocation.longitude);
            
            measurementSession.latitude = [NSNumber numberWithDouble:latestLocation.latitude];
            measurementSession.longitude = [NSNumber numberWithDouble:latestLocation.longitude];
        }
        else {
            measurementSession.latitude = nil;
            measurementSession.longitude = nil;
        }
        
        if ([self.delegate respondsToSelector:@selector(updateLocation:longitude:)]) {
            [self.delegate updateLocation:measurementSession.latitude longitude:measurementSession.longitude];
        }
    }
}

#pragma mark Temperature methods

- (void)initiateTemperatureLookup {
    NSLog(@"[SavingWindMeasurementController] initiateTemperatureLookup");
    
    MeasurementSession *measurementSession = [self getLatestMeasurementSession];
    if (measurementSession && [measurementSession.measuring boolValue]) {

        //NSLog(@"[SavingWindMeasurementController] Has measurement session");
        
        CLLocationCoordinate2D latestLocation = [LocationManager sharedInstance].latestLocation;
        if ([LocationManager isCoordinateValid:latestLocation]) {

            NSLog(@"[SavingWindMeasurementController] Has location");

            if (self.temperatureLookupTimer) {
                [self.temperatureLookupTimer invalidate];
                self.temperatureLookupTimer = nil;
            }
            
            [[ServerUploadManager sharedInstance] lookupTemperatureForLocation:latestLocation.latitude longitude:latestLocation.longitude success:^(NSNumber *temperature, NSNumber *direction) {
                
                NSLog(@"[SavingWindMeasurementController] Got success looking up temperature: %@", temperature);
                if (temperature) {

                    BOOL updatedDirection = NO;
                    
                    MeasurementSession *measurementSession = [self getLatestMeasurementSession];

                    if (measurementSession) {
                        measurementSession.temperature = temperature;

                        BOOL hasDirection = (measurementSession.windDirection && (measurementSession.windDirection != (id)[NSNull null]));
                        if (!hasDirection) {
                            measurementSession.windDirection = direction;
                            self.currentDirection = direction;
                            updatedDirection = YES;
                        }
                        
                        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
                    }

                    if ([self.delegate respondsToSelector:@selector(updateTemperature:)]) {
                        [self.delegate updateTemperature:temperature];
                    }

                    if (updatedDirection && [self.delegate respondsToSelector:@selector(updateDirection:)]) {
                        [self.delegate updateDirection:direction];
                    }
                }
            } failure:^(NSError *error) {
                NSLog(@"[SavingWindMeasurementController] Got error looking up temperature: %@", error);
            }];
        }
    }
}

@end
