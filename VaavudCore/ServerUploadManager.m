//
//  ServerUploadManager.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 19/06/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#define consecutiveNetworkErrorBackOffThreshold 3
#define networkErrorBackOff 10

#import "ServerUploadManager.h"
#import "SharedSingleton.h"
#import "MeasurementSession+Util.h"
#import "VaavudAPIHTTPClient.h"

@interface ServerUploadManager () {
}

@property(nonatomic) NSTimer *syncTimer;
@property(nonatomic) BOOL hasReachability;
@property(nonatomic) BOOL justDidBecomeActive;
@property(nonatomic) int consecutiveNetworkErrors;
@property(nonatomic) int backoffWaitCount;

@end

@implementation ServerUploadManager

SHARED_INSTANCE

- (id) init {
    self = [super init];
    
    if (self) {
        self.consecutiveNetworkErrors = 0;
        self.backoffWaitCount = 0;
        self.hasReachability = NO;
        self.justDidBecomeActive = YES;

        // initialize HTTP client
        [[VaavudAPIHTTPClient sharedInstance] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status){
            /*
             AFNetworkReachabilityStatusUnknown          = -1,
             AFNetworkReachabilityStatusNotReachable     = 0,
             AFNetworkReachabilityStatusReachableViaWWAN = 1,
             AFNetworkReachabilityStatusReachableViaWiFi = 2,
             */
            NSLog(@"[ServerUploadManager, %@] Reachability status changed to: %d", [NSThread currentThread], status);

            if (status == 1 || status == 2) {
                self.hasReachability = YES;
                [self handleDidBecomeActiveTasks];
            }
            else {
                self.hasReachability = NO;
            }
        }];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    }
    
    return self;
}

- (void) start {
    self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(checkForUnUploadedData) userInfo:nil repeats:YES];
}

// notification from the OS
- (void) appDidBecomeActive:(NSNotification*) notification {
    NSLog(@"[ServerUploadManager] appDidBecomeActive");
    self.justDidBecomeActive = YES;
    [self handleDidBecomeActiveTasks];
}

// notification from the OS
-(void) appWillTerminate:(NSNotification*) notification {
    NSLog(@"[ServerUploadManager] appWillTerminate");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

// this is triggered by the OS informing us that the app did become active or AFNetworking telling us that reachability has changed to YES and we haven't yet executed these tasks after becoming active. Thus, if we don't have reachability when becoming active, these tasks are postponed until reachability changes to YES.
- (void) handleDidBecomeActiveTasks {
    if (self.justDidBecomeActive == NO || self.hasReachability == NO) {
        return;
    }
    NSLog(@"[ServerUploadManager, %@] Handle did-become-active tasks", [NSThread currentThread]);
    self.justDidBecomeActive = NO;
    // TODO: place configure call here
    [self triggerUpload];    
}

- (void) triggerUpload {
    NSLog(@"[ServerUploadManager, %@] Trigger upload", [NSThread currentThread]);
    [self checkForUnUploadedData];
}

- (void) checkForUnUploadedData {
    
    if (!self.hasReachability) {
        return;
    }
    
    if (self.consecutiveNetworkErrors >= consecutiveNetworkErrorBackOffThreshold) {
        self.backoffWaitCount++;
        if (self.backoffWaitCount % networkErrorBackOff != 0) {
            NSLog(@"[ServerUploadManager, %@] Backing off due to %d consecutive network errors, wait count is %d", [NSThread currentThread], self.consecutiveNetworkErrors, self.backoffWaitCount);
            return;
        }
    }
    

    NSArray *unuploadedMeasurementSessions = [MeasurementSession findByAttribute:@"uploaded" withValue:[NSNumber numberWithBool:NO]];

    if (unuploadedMeasurementSessions && [unuploadedMeasurementSessions count] > 0) {
        
        NSLog(@"[ServerUploadManager, %@] Found %d un-uploaded MeasurementSessions", [NSThread currentThread], [unuploadedMeasurementSessions count]);
        
        for (MeasurementSession *measurementSession in unuploadedMeasurementSessions) {

            NSNumber *pointCount = [NSNumber numberWithUnsignedInteger:[measurementSession.points count]];

            NSLog(@"[ServerUploadManager, %@] Found non-uploaded MeasurementSession with uuid=%@, startTime=%@, endTime=%@, measuring=%@, uploadedIndex=%@, pointCount=%@", [NSThread currentThread], measurementSession.uuid, measurementSession.startTime, measurementSession.endTime, measurementSession.measuring, measurementSession.uploadedIndex, pointCount);

            if ([measurementSession.measuring boolValue] == YES) {
                
                // if an unuploaded 
                NSTimeInterval howRecent = [measurementSession.endTime timeIntervalSinceNow];
                if (abs(howRecent) > 3600.0) {
                    NSLog(@"[ServerUploadManager, %@] Found old MeasurementSession that is still measuring - setting it to not measuring", [NSThread currentThread]);
                    measurementSession.measuring = [NSNumber numberWithBool:NO];
                    [[NSManagedObjectContext defaultContext] saveToPersistentStoreWithCompletion:nil];
                }
            }
            
            if ([measurementSession.uploadedIndex intValue] == [pointCount intValue]) {

                if ([measurementSession.measuring boolValue] == NO) {
                    NSLog(@"[ServerUploadManager, %@] Found MeasurementSession that is not measuring and has no new points, so setting it as uploaded", [NSThread currentThread]);
                    measurementSession.uploaded = [NSNumber numberWithBool:YES];
                    [[NSManagedObjectContext defaultContext] saveToPersistentStoreWithCompletion:nil];
                }
                else {
                    NSLog(@"[ServerUploadManager, %@] Found MeasurementSession that is not uploaded, is still measuring, but has no new points, so skipping", [NSThread currentThread]);
                }
            }
            else {
                
                NSLog(@"[ServerUploadManager, %@] Found MeasurementSession that is not uploaded", [NSThread currentThread]);

                NSDictionary *parameters = [measurementSession toDictionary];
                
                [[VaavudAPIHTTPClient sharedInstance] postPath:@"/api/measure" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                    NSLog(@"[ServerUploadManager, %@] Got successful response: %@", [NSThread currentThread], responseObject);
                    
                    // clear consecutive errors since we got a successful reponse
                    self.consecutiveNetworkErrors = 0;
                    self.backoffWaitCount = 0;
                    
                    measurementSession.uploadedIndex = pointCount;

                    if ([measurementSession.measuring boolValue] == NO) {
                        // since we're not measuring and got a successful reponse, we're done, so set as not uploading
                        NSLog(@"[ServerUploadManager, %@] Setting MeasurementSession as uploaded", [NSThread currentThread]);
                        measurementSession.uploaded = [NSNumber numberWithBool:YES];
                    }
                    [[NSManagedObjectContext defaultContext] saveToPersistentStoreWithCompletion:nil];
                    
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"[ServerUploadManager, %@] Got error: %@", [NSThread currentThread], error);
                    
                    self.consecutiveNetworkErrors++;
                }];
                
                // stop iterating since we did process a measurement session to ensure that we don't spam the server in case the user has a lot of unloaded measurement sessions
                break;
            }
        }
    }
    else {
        NSLog(@"[ServerUploadManager, %@] Found no uploading MeasurementSession", [NSThread currentThread]);
    }
}

@end
