//
//  AccountUtil.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 19/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

enum AuthenticationActionType : NSUInteger {
    AuthenticationActionLogin = 1,
    AuthenticationActionSignup = 2
};

enum AuthenticationStateType : NSUInteger {
    AuthenticationStateNeverLoggedIn = 1,
    AuthenticationStateLoggedIn = 2,
    AuthenticationStateWasLoggedIn = 3
};

enum AuthenticationResponseType : NSUInteger {
    AuthenticationResponseCreated = 1,
    AuthenticationResponsePaired = 2,
    AuthenticationResponseGenericError = 3,
    AuthenticationResponseMalformedEmail = 4,
    AuthenticationResponseInvalidCredentials = 5,
    AuthenticationResponseInvalidAccessToken = 6,
    AuthenticationResponseFacebookUserMessage = 7,
    AuthenticationResponseFacebookUserCancelled = 8,
    AuthenticationResponseFacebookReopenSession = 9
};

@interface AccountUtil : NSObject

+ (AccountUtil *) sharedInstance;

// register methods

+(void) registerWithPassword:(NSString*)password email:(NSString*)email firstName:(NSString*)firstName lastName:(NSString*)lastName action:(enum AuthenticationActionType)action success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response))failure;

+(void) logout;

+(BOOL) isLoggedIn;

// facebook methods used from the AppDelegate

+(NSArray*) facebookSignupPermissions;

+(void) facebookSessionStateChanged:(FBSession*)session state:(FBSessionState)state error:(NSError*)error action:(enum AuthenticationActionType)action success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response, NSString* message, BOOL displayFeedback))failure;

@end
