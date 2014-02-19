//
//  AccountUtil.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 19/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AccountUtil.h"
#import "SharedSingleton.h"
#import "Property+Util.h"
#import "VaavudAPIHTTPClient.h"
#import "ServerUploadManager.h"
#import "UUIDUtil.h"
#import "PasswordUtil.h"
#import "vaavudAppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation AccountUtil

SHARED_INSTANCE

+(void) registerWithPassword:(NSString*)password email:(NSString*)email firstName:(NSString*)firstName lastName:(NSString*)lastName action:(enum AuthenticationActionType)action success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response))failure {

    NSString *passwordHash = [PasswordUtil createHash:password salt:email];
    
    [[ServerUploadManager sharedInstance] registerUser:[self actionToString:action] email:email passwordHash:passwordHash facebookId:nil facebookAccessToken:nil firstName:firstName lastName:lastName gender:nil verified:[NSNumber numberWithInt:0] retry:3 success:^(NSString *status) {
        
        enum AuthenticationResponseType response = [self stringToAuthenticationResponse:status];
        
        if (response == AuthenticationResponsePaired || response == AuthenticationResponseCreated) {

            [Property setAsString:email forKey:KEY_EMAIL];
            [AccountUtil setAuthenticationState:AuthenticationStateLoggedIn];

            if (success) {
                success(response);
            }
        }
        else {
            if (failure) {
                failure(response);
            }
        }
    } failure:^(NSError *error) {
        NSLog(@"[AccountUtil] error registering user");
        if (failure) {
            failure(AuthenticationResponseGenericError);
        }
    }];
}

+(NSArray*) facebookSignupPermissions {
    return @[@"basic_info", @"email"];
}

+ (void) facebookSessionStateChanged:(FBSession*)session state:(FBSessionState)state error:(NSError*)error action:(enum AuthenticationActionType)action success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response, NSString* message, BOOL displayFeedback))failure {
    
    if (!error && state == FBSessionStateOpen) {
        // If the session was opened successfully
        NSLog(@"[AccountUtil] Facebook session opened");
        [self facebookUserLoggedIn:action success:success failure:failure];
        return;
    }
    
    if (error) {
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES) {
            // If the error requires people using an app to make an action outside of the app in order to recover
            if (failure) {
                failure(AuthenticationResponseFacebookUserMessage, [FBErrorUtility userMessageForError:error], YES);
            }
        }
        else {
            FBErrorCategory errorCategory = [FBErrorUtility errorCategoryForError:error];
            
            if (errorCategory == FBErrorCategoryUserCancelled) {
                // If the user cancelled login
                NSLog(@"[VaavudAppDelegate] Facebook user cancelled login");
                if (failure) {
                    failure(AuthenticationResponseFacebookUserCancelled, nil, NO);
                }
            }
            else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
                NSLog(@"[VaavudAppDelegate] Facebook authentication reopen session");
                if (failure) {
                    failure(AuthenticationResponseFacebookReopenSession, nil, NO);
                }
            }
            else {
                NSLog(@"[VaavudAppDelegate] Facebook error %d", errorCategory);
                if (failure) {
                    failure(AuthenticationResponseGenericError, nil, YES);
                }
            }
        }
        
        [AccountUtil logout];
    }
    else {
        if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed) {
            NSLog(@"[VaavudAppDelegate] Facebook session closed");
            [AccountUtil logout];
        }
        if (failure) {
            failure(AuthenticationResponseGenericError, nil, YES);
        }
    }
}

+ (void)facebookUserLoggedIn:(enum AuthenticationActionType)action success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response, NSString* message, BOOL displayFeedback))failure {
    NSLog(@"[AccountUtil] facebookUserLoggedIn");
    
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            
            FBAccessTokenData *accessTokenData = FBSession.activeSession.accessTokenData;
            [Property setAsString:accessTokenData.accessToken forKey:KEY_FACEBOOK_ACCESS_TOKEN];
            [Property setAsString:[result objectForKey:@"id"] forKey:KEY_FACEBOOK_USER_ID];
            
            NSString *facebookUserId = [Property getAsString:KEY_FACEBOOK_USER_ID];
            NSString *facebookAccessToken = [Property getAsString:KEY_FACEBOOK_ACCESS_TOKEN];
            NSString *email = [result objectForKey:@"email"];
            NSString *firstName = [result objectForKey:@"first_name"];
            NSString *lastName = [result objectForKey:@"last_name"];
            NSString *genderString = [result objectForKey:@"gender"];
            NSNumber *gender = [NSNumber numberWithInt:0];
            if (genderString) {
                gender = ([@"male" isEqualToString:genderString]) ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:2];
            }
            NSNumber *verified = [result objectForKey:@"verified"];
            
            NSLog(@"[AccountUtil] Facebook logged in - facebookUserId=%@, accessToken=%@, email=%@, firstName=%@, lastName=%@, gender=%@, verified=%@", facebookUserId, facebookAccessToken, email, firstName, lastName, gender, verified);
            
            [[ServerUploadManager sharedInstance] registerUser:[self actionToString:action] email:email passwordHash:nil facebookId:facebookUserId facebookAccessToken:facebookAccessToken firstName:firstName lastName:lastName gender:gender verified:verified retry:3 success:^(NSString *status) {
                
                enum AuthenticationResponseType response = [self stringToAuthenticationResponse:status];
                
                if (response == AuthenticationResponsePaired || response == AuthenticationResponseCreated) {
                    [AccountUtil setAuthenticationState:AuthenticationStateLoggedIn];
                    if (success) {
                        success(response);
                    }
                }
                else {
                    if (failure) {
                        failure(response, nil, YES);
                    }
                }
            } failure:^(NSError *error) {
                if (failure) {
                    failure(AuthenticationResponseGenericError, nil, YES);
                }
            }];
        }
        else {
            if (failure) {
                failure(AuthenticationResponseGenericError, nil, YES);
            }
        }
    }];
}

+(void) logout {

    if (![self isLoggedIn]) {
        return;
    }

    [Property setAsString:nil forKey:KEY_FACEBOOK_ACCESS_TOKEN];
    if ([self getAuthenticationState] != AuthenticationStateNeverLoggedIn) {
        [self setAuthenticationState:AuthenticationStateWasLoggedIn];
    }
    
    [Property setAsString:nil forKey:KEY_AUTH_TOKEN];
    [Property setAsString:[UUIDUtil generateUUID] forKey:KEY_DEVICE_UUID];
    if ([self getAuthenticationState] != AuthenticationStateNeverLoggedIn) {
        [self setAuthenticationState:AuthenticationStateWasLoggedIn];
    }
    [[VaavudAPIHTTPClient sharedInstance] setAuthToken:nil];

    if (FBSession.activeSession && FBSession.activeSession.state == FBSessionStateOpen) {
        // note: this will cause the AppDelegate's Facebook handler to call this method recursively
        // but since we've already changed AuthenticationState to not logged-in, the first 'if'
        // in this method will cause a return immediately
        [FBSession.activeSession closeAndClearTokenInformation];
    }
    
    [[ServerUploadManager sharedInstance] registerDevice];
}

+ (BOOL) isLoggedIn {
    return [self getAuthenticationState] == AuthenticationStateLoggedIn;
}

+ (void) setAuthenticationState:(enum AuthenticationStateType)state {
    [Property setAsInteger:[NSNumber numberWithInt:state] forKey:KEY_AUTHENTICATION_STATE];
}

+ (enum AuthenticationStateType) getAuthenticationState {
    NSNumber *authState = [Property getAsInteger:KEY_AUTHENTICATION_STATE];
    if (!authState) {
        return AuthenticationStateNeverLoggedIn;
    }
    else {
        return [authState integerValue];
    }
}

+ (NSString*) actionToString:(enum AuthenticationActionType)action {
    switch (action) {
        case AuthenticationActionLogin:
            return @"LOGIN";
        case AuthenticationActionSignup:
            return @"SIGNUP";
    }
}

+ (enum AuthenticationResponseType) stringToAuthenticationResponse:(NSString*)response {
    if ([@"CREATED" isEqualToString:response]) {
        return AuthenticationResponseCreated;
    }
    else if ([@"PAIRED" isEqualToString:response]) {
        return AuthenticationResponsePaired;
    }
    else if ([@"MALFORMED_EMAIL" isEqualToString:response]) {
        return AuthenticationResponseMalformedEmail;
    }
    else if ([@"INVALID_CREDENTIALS" isEqualToString:response]) {
        return AuthenticationResponseInvalidCredentials;
    }
    else if ([@"INVALID_ACCESS_TOKEN" isEqualToString:response]) {
        return AuthenticationResponseInvalidAccessToken;
    }
    else {
        return AuthenticationResponseGenericError;
    }
}

@end
