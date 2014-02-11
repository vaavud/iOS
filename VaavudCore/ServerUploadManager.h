//
//  ServerUploadManager.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 19/06/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MeasurementSession.h"

@interface ServerUploadManager : NSObject

+ (ServerUploadManager *) sharedInstance;

- (void) start;

- (void) triggerUpload;

-(void) readMeasurements:(int)hours retry:(int)retryCount success:(void (^)(NSArray *measurements))success failure:(void (^)(NSError *error))failure;

-(void) registerUser:(NSString*)email passwordHash:(NSString*)passwordHash facebookId:(NSString*)facebookId facebookAccessToken:(NSString*)facebookAccessToken firstName:(NSString*)firstName lastName:(NSString*)lastName retry:(int)retryCount success:(void (^)(NSString *status))success failure:(void (^)(NSError *error))failure;

@end
