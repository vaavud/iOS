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
@property(nonatomic) BOOL isActive;
@property(nonatomic) int consecutiveNetworkErrors;
@property(nonatomic) int backoffWaitCount;

@end

@implementation ServerUploadManager

SHARED_INSTANCE

- (id) init {
    self = [super init];
    
    if (self) {
        // initialize HTTP client
        [[VaavudAPIHTTPClient sharedInstance] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status){
            /*
             AFNetworkReachabilityStatusUnknown          = -1,
             AFNetworkReachabilityStatusNotReachable     = 0,
             AFNetworkReachabilityStatusReachableViaWWAN = 1,
             AFNetworkReachabilityStatusReachableViaWiFi = 2,
             */
            NSLog(@"[ServerUploadManager] Reachability status changed to: %d", status);

            if (status == 1 || status == 2) {
                self.isActive = YES;
            }
            else {
                self.isActive = NO;
            }
        }];

        self.consecutiveNetworkErrors = 0;
        self.backoffWaitCount = 0;
    }
    
    return self;
}

- (void) start {
    self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(checkForUnUploadedData) userInfo:nil repeats:YES];
}

- (void) triggerUpload {
    [self checkForUnUploadedData];
}

- (void) checkForUnUploadedData {
    
    if (!self.isActive) {
        return;
    }
    
    if (self.consecutiveNetworkErrors >= consecutiveNetworkErrorBackOffThreshold) {
        self.backoffWaitCount++;
        if (self.backoffWaitCount % networkErrorBackOff != 0) {
            NSLog(@"[ServerUploadManager] Backing off due to %d consecutive network errors, wait count is %d", self.consecutiveNetworkErrors, self.backoffWaitCount);
            return;
        }
    }
    
    MeasurementSession *measurementSession = [MeasurementSession findFirstByAttribute:@"uploaded" withValue:[NSNumber numberWithBool:NO]];

    if (measurementSession) {

        if (![measurementSession.measuring boolValue]) {

            NSLog(@"[ServerUploadManager] Found MeasurementSession that is not uploaded with startTime %@", measurementSession.startTime);

            NSDictionary *parameters = [measurementSession toDictionary];
            
            [[VaavudAPIHTTPClient sharedInstance] postPath:@"/api/measure" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                NSLog(@"[ServerUploadManager] Got successful response: %@", responseObject);
                
                // clear consecutive errors since we got a successful reponse
                self.consecutiveNetworkErrors = 0;
                self.backoffWaitCount = 0;

                // note: only mark as uploaded when we got a successful response
                NSLog(@"[ServerUploadManager] Setting MeasurementSession as uploaded");
                measurementSession.uploaded = [NSNumber numberWithBool:YES];
                [[NSManagedObjectContext defaultContext] saveToPersistentStoreWithCompletion:nil];

            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"[ServerUploadManager] Got error: %@", error);
                
                self.consecutiveNetworkErrors++;
            }];
        }
        else {
            NSLog(@"[ServerUploadManager] Found MeasurementSession that is not uploaded but it is still measuring");   
        }
    }
    else {
        NSLog(@"[ServerUploadManager] Found no uploading MeasurementSession");
    }
}

@end
