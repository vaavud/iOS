//
//  vaavudAppDelegate.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface vaavudAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) NSString* xCallbackSuccess;

- (NSArray*)facebookSignupPermissions;
- (void)facebookSessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error action:(NSString*)action success:(void(^)(NSString *status))success failure:(void(^)(NSString *status, NSString *message, BOOL displayFeedback))failure;

@end
