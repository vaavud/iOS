//
//  AccountManager.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 19/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AccountManager.h"
#import "SharedSingleton.h"
#import "Property+Util.h"
#import "VaavudAPIHTTPClient.h"
#import "ServerUploadManager.h"
#import "UUIDUtil.h"
#import "PasswordUtil.h"
#import "vaavudAppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation AccountManager

SHARED_INSTANCE

int facebookRegisterIdentifier = 0;
BOOL hasCalledDelegateForCurrentFacebookRegisterIdentifier = NO;

-(void) registerWithPassword:(NSString*)password email:(NSString*)email firstName:(NSString*)firstName lastName:(NSString*)lastName action:(enum AuthenticationActionType)action success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response))failure {

    if (![ServerUploadManager sharedInstance].hasReachability) {
        failure(AuthenticationResponseNoReachability);
        return;
    }
    
    NSString *passwordHash = [PasswordUtil createHash:password salt:email];
    
    [self registerUser:action email:email passwordHash:passwordHash facebookId:nil facebookAccessToken:nil firstName:firstName lastName:lastName gender:nil verified:[NSNumber numberWithInt:0] success:success failure:failure];
}

-(void) registerWithFacebook:(NSString*)password action:(enum AuthenticationActionType)action {
    [self registerWithFacebook:password action:action isRecursive:NO];
}

-(void) registerWithFacebook:(NSString*)password action:(enum AuthenticationActionType)action isRecursive:(BOOL)isRecursive {

    if (![ServerUploadManager sharedInstance].hasReachability) {
        if (self.delegate) {
            [self.delegate facebookAuthenticationFailure:AuthenticationResponseNoReachability message:nil displayFeedback:YES];
        }
        return;
    }

    int fbRegId = facebookRegisterIdentifier++;
    hasCalledDelegateForCurrentFacebookRegisterIdentifier = NO;
    
    if (action == AuthenticationActionRefresh) {
        if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
            NSLog(@"[AccountManager] Found a cached Facebook session");
            
            // If there's one, just open the session silently, without showing the user the login UI
            [FBSession openActiveSessionWithReadPermissions:[self facebookSignupPermissions]
                                               allowLoginUI:NO
                                          completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                              [self facebookSessionStateChanged:session state:state error:error password:password action:AuthenticationActionLogin success:nil failure:nil];
                                          }];
        }
    }
    else {
        [FBSession openActiveSessionWithReadPermissions:[self facebookSignupPermissions]
                                           allowLoginUI:YES
                                      completionHandler:
         ^(FBSession *session, FBSessionState state, NSError *error) {
             [self facebookSessionStateChanged:session state:state error:error password:password action:action success:^(enum AuthenticationResponseType response) {

                 hasCalledDelegateForCurrentFacebookRegisterIdentifier = YES;
                 if (self.delegate) {
                     [self.delegate facebookAuthenticationSuccess:response];
                 }
                 
             } failure:^(enum AuthenticationResponseType response, NSString *message, BOOL displayFeedback) {

                 // We only want to notify about failures if it is related to the newest Facebook register call.
                 // If it is related to an older call, we assume that the newer call will either succeed or fail
                 // with a more current error notification.

                 if (facebookRegisterIdentifier == (fbRegId + 1)) {
                     if (hasCalledDelegateForCurrentFacebookRegisterIdentifier) {
                         NSLog(@"[AccountManager] Skipping delegate failure call because delegate has already been called");
                         return;
                     }
                     else {
                         hasCalledDelegateForCurrentFacebookRegisterIdentifier = YES;
                         
                         // If we get a reopen-session response, automatically try to register again unless
                         // we already did that recursively.
                         // This situation is probably due to a valid cached access token resulting in a
                         // user-logged-in response but failing when trying to call the Graph API to get
                         // user information (this triggers the reopen-session response).
                         
                         if (response == AuthenticationResponseFacebookReopenSession && !isRecursive) {
                             [self registerWithFacebook:password action:action isRecursive:YES];
                         }
                         else if (self.delegate) {
                             [self.delegate facebookAuthenticationFailure:response message:message displayFeedback:displayFeedback];
                         }
                     }
                 }
                 else {
                     NSLog(@"[AccountManager] Skipping delegate failure call because a newer Facebook register call is in progress");
                 }
             }];
         }];
    }
}

-(NSArray*) facebookSignupPermissions {
    return @[@"basic_info", @"email"];
}

-(void) facebookSessionStateChanged:(FBSession*)session state:(FBSessionState)state error:(NSError*)error password:(NSString*)password action:(enum AuthenticationActionType)action success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response, NSString* message, BOOL displayFeedback))failure {
    
    if (!error && state == FBSessionStateOpen) {
        // If the session was opened successfully
        //NSLog(@"[AccountManager] Facebook session opened");
        [self facebookUserLoggedIn:action password:password success:success failure:failure];
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
                NSLog(@"[AccountManager] Facebook user cancelled login");
                if (failure) {
                    failure(AuthenticationResponseFacebookUserCancelled, nil, NO);
                }
            }
            else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
                NSLog(@"[AccountManager] Facebook authentication reopen session");
                if (failure) {
                    failure(AuthenticationResponseFacebookReopenSession, nil, NO);
                }
            }
            else {
                NSLog(@"[AccountManager] Facebook error %d", errorCategory);
                if (failure) {
                    failure(AuthenticationResponseGenericError, nil, YES);
                }
            }
        }
        
        [self logout];
    }
    else {
        if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed) {
            NSLog(@"[AccountManager] Facebook session closed");
            [self logout];
        }
        if (failure) {
            failure(AuthenticationResponseGenericError, nil, YES);
        }
    }
}

-(void) facebookUserLoggedIn:(enum AuthenticationActionType)action password:(NSString*)password success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response, NSString* message, BOOL displayFeedback))failure {
    //NSLog(@"[AccountManager] facebookUserLoggedIn");
    
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
            
            NSString *passwordHash = nil;
            if (password && password.length > 0 && email && email.length > 0) {
                passwordHash = [PasswordUtil createHash:password salt:email];
            }

            NSLog(@"[AccountManager] Facebook logged in: facebookUserId=%@, email=%@", facebookUserId, email);
            
            [self registerUser:action email:email passwordHash:passwordHash facebookId:facebookUserId facebookAccessToken:facebookAccessToken firstName:firstName lastName:lastName gender:gender verified:verified success:success failure:^(enum AuthenticationResponseType response) {
                if (failure) {
                    failure(response, nil, YES);
                }
            }];
        }
        else {
            NSLog(@"[AccountManager] Failure calling Graph API to get user info");
            if (failure) {
                failure(AuthenticationResponseGenericError, nil, YES);
            }
        }
    }];
}

-(void) registerUser:(enum AuthenticationActionType)action email:(NSString*)email passwordHash:(NSString*)passwordHash facebookId:(NSString*)facebookId facebookAccessToken:(NSString*)facebookAccessToken firstName:(NSString*)firstName lastName:(NSString*)lastName gender:(NSNumber*)gender verified:(NSNumber*)verified success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response))failure {
    
    [[ServerUploadManager sharedInstance] registerUser:[self actionToString:action] email:email passwordHash:passwordHash facebookId:facebookId facebookAccessToken:facebookAccessToken firstName:firstName lastName:lastName gender:gender verified:verified retry:3 success:^(NSString *status, id responseObject) {
        
        enum AuthenticationResponseType authResponse = [self stringToAuthenticationResponse:status];
        
        if (authResponse == AuthenticationResponsePaired || authResponse == AuthenticationResponseCreated) {
            
            [self setAuthenticationState:AuthenticationStateLoggedIn];
            
            NSNumber *userId = [responseObject objectForKey:@"userId"];
            if (userId && ![lastName isEqual:[NSNull null]] && !isnan([userId longLongValue]) && ([userId longLongValue] > 0)) {
                [Property setAsLongLong:userId forKey:KEY_USER_ID];
            }
            
            NSString *email = [responseObject objectForKey:@"email"];
            if (email && ![lastName isEqual:[NSNull null]] && email.length > 0) {
                [Property setAsString:email forKey:KEY_EMAIL];
            }
            
            NSString *firstName = [responseObject objectForKey:@"firstName"];
            if (firstName && ![lastName isEqual:[NSNull null]] && firstName.length > 0) {
                [Property setAsString:firstName forKey:KEY_FIRST_NAME];
            }
            
            NSString *lastName = [responseObject objectForKey:@"lastName"];
            if (lastName && ![lastName isEqual:[NSNull null]] && lastName.length > 0) {
                [Property setAsString:lastName forKey:KEY_LAST_NAME];
            }
            
            if (success) {
                success(authResponse);
            }
        }
        else {
            if (failure) {
                failure(authResponse);
            }
        }
    } failure:^(NSError *error) {
        NSLog(@"[AccountManager] error registering user");
        if (failure) {
            failure(AuthenticationResponseGenericError);
        }
    }];
}

-(void) logout {
    
    //NSLog(@"[AccountManager] logout");

    [Property setAsString:nil forKey:KEY_FACEBOOK_ACCESS_TOKEN];
    [Property setAsString:nil forKey:KEY_AUTH_TOKEN];
    [Property setAsString:[UUIDUtil generateUUID] forKey:KEY_DEVICE_UUID];
    if ([self getAuthenticationState] != AuthenticationStateNeverLoggedIn) {
        [self setAuthenticationState:AuthenticationStateWasLoggedIn];
    }
    [[VaavudAPIHTTPClient sharedInstance] setAuthToken:nil];

    if (FBSession.activeSession && FBSession.activeSession.state != FBSessionStateClosed) {
        // note: this will cause the completion handler previously used in opening the Facebook session
        // to call this method recursively but since we've already changed AuthenticationState to
        // not logged-in, the first 'if' in this method will cause a return immediately
        //NSLog(@"[AccountManager] logout - closeAndClearTokenInformation");
        [FBSession.activeSession closeAndClearTokenInformation];
    }
    
    [[ServerUploadManager sharedInstance] registerDevice];
}

-(BOOL) isLoggedIn {
    return [self getAuthenticationState] == AuthenticationStateLoggedIn;
}

-(void) setAuthenticationState:(enum AuthenticationStateType)state {
    [Property setAsInteger:[NSNumber numberWithInt:state] forKey:KEY_AUTHENTICATION_STATE];
}

-(enum AuthenticationStateType) getAuthenticationState {
    NSNumber *authState = [Property getAsInteger:KEY_AUTHENTICATION_STATE];
    if (!authState) {
        return AuthenticationStateNeverLoggedIn;
    }
    else {
        return [authState integerValue];
    }
}

-(NSString*) actionToString:(enum AuthenticationActionType)action {
    switch (action) {
        case AuthenticationActionLogin:
            return @"LOGIN";
        case AuthenticationActionSignup:
            return @"SIGNUP";
        case AuthenticationActionRefresh:
            return @"REFRESH";
    }
}

-(enum AuthenticationResponseType) stringToAuthenticationResponse:(NSString*)response {
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
    else if ([@"INVALID_FACEBOOK_ACCESS_TOKEN" isEqualToString:response]) {
        return AuthenticationResponseFacebookInvalidAccessToken;
    }
    else if ([@"EMAIL_USED_PROVIDE_PASSWORD" isEqualToString:response]) {
        return AuthenticationResponseEmailUsedProvidePassword;
    }
    else if ([@"LOGIN_WITH_FACEBOOK" isEqualToString:response]) {
        return AuthenticationResponseLoginWithFacebook;
    }
    else if ([@"INVALID_FACEBOOK_ACCESS_TOKEN" isEqualToString:response]) {
        return AuthenticationResponseFacebookInvalidAccessToken;
    }
    else {
        return AuthenticationResponseGenericError;
    }
}

@end
