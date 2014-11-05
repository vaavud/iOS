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
#import "Mixpanel.h"
#import "MixpanelUtil.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation AccountManager

SHARED_INSTANCE

int facebookRegisterIdentifier = 0;
BOOL hasCalledDelegateForCurrentFacebookRegisterIdentifier = NO;
BOOL isDoingLogout = NO;

- (void) registerWithPassword:(NSString*)password email:(NSString*)email firstName:(NSString*)firstName lastName:(NSString*)lastName action:(enum AuthenticationActionType)action success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response))failure {

    isDoingLogout = NO;
    
    if (![ServerUploadManager sharedInstance].hasReachability) {
        failure(AuthenticationResponseNoReachability);
        return;
    }
    
    NSString *passwordHash = [PasswordUtil createHash:password salt:email];
    NSDictionary *metaInfo = @{@"metaMethod":@"registerWithPassword", @"metaAppAction":[self actionToString:action]};
    
    [self registerUser:action email:email passwordHash:passwordHash facebookId:nil facebookAccessToken:nil firstName:firstName lastName:lastName gender:nil verified:[NSNumber numberWithInt:0] metaInfo:metaInfo success:success failure:failure];
}

- (void) logout {
    isDoingLogout = NO;
    // make sure delegate is not called
    facebookRegisterIdentifier++;
    hasCalledDelegateForCurrentFacebookRegisterIdentifier = YES;
    [self doLogout];
}

- (void) registerWithFacebook:(NSString*)password action:(enum AuthenticationActionType)action {
    [self registerWithFacebook:password action:action isRecursive:NO];
}

- (void) registerWithFacebook:(NSString*)password action:(enum AuthenticationActionType)action isRecursive:(BOOL)isRecursive {

    int fbRegId = facebookRegisterIdentifier++;
    hasCalledDelegateForCurrentFacebookRegisterIdentifier = NO;
    isDoingLogout = NO;
    
    //NSLog(@"[AccountManager] registerWithFacebook, fbRegId=%u", fbRegId);
    
    if (action == AuthenticationActionRefresh) {
        if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
            NSLog(@"[AccountManager] Found a cached Facebook session");
            
            // If there's one, just open the session silently, without showing the user the login UI
            [FBSession openActiveSessionWithReadPermissions:[self facebookSignupPermissions]
                                               allowLoginUI:NO
                                          completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                              [self facebookSessionStateChanged:session state:state error:error password:password action:action success:nil failure:^(enum AuthenticationResponseType response, NSString *message, BOOL displayFeedback) {
                                                  
                                                  NSLog(@"[AccountManager] Failure refreshing Facebook session");
                                                  
                                                  if (facebookRegisterIdentifier == (fbRegId + 1) && (response == AuthenticationResponseFacebookReopenSession)) {
                                                      [self logout];
                                                  }
                                              }];
                                          }];
        }
    }
    else {
        if (![ServerUploadManager sharedInstance].hasReachability) {
            if (self.delegate) {
                [self.delegate facebookAuthenticationFailure:AuthenticationResponseNoReachability message:nil displayFeedback:YES];
            }
            return;
        }
        
        void(^success)(enum AuthenticationResponseType response) = ^(enum AuthenticationResponseType response) {
            //NSLog(@"[AccountManager] Delegate success, fbRegId=%u", fbRegId);
            hasCalledDelegateForCurrentFacebookRegisterIdentifier = YES;
            if (self.delegate) {
                [self.delegate facebookAuthenticationSuccess:response];
            }
        };
        
        void(^failure)(enum AuthenticationResponseType response, NSString* message, BOOL displayFeedback) = ^(enum AuthenticationResponseType response, NSString *message, BOOL displayFeedback) {
            
            // We only want to notify about failures if it is related to the newest Facebook register call.
            // If it is related to an older call, we assume that the newer call will either succeed or fail
            // with a more current error notification.
            
            if (facebookRegisterIdentifier == (fbRegId + 1)) {
                if (hasCalledDelegateForCurrentFacebookRegisterIdentifier) {
                    NSLog(@"[AccountManager] Skipping delegate failure call because delegate has already been called, fbRegId=%u", fbRegId);
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
                NSLog(@"[AccountManager] Skipping delegate failure call because a newer Facebook register call is in progress, fbRegId=%u", fbRegId);
            }
        };
        
        // Check if Facebook session is already open (might happen if the Facebook login part went ok, but registering on our server failed)
        if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
            NSLog(@"[AccountManager] Facebook session already open");
            [self facebookUserLoggedIn:action password:password isRecursive:NO success:success failure:failure];
        }
        else {
            [FBSession openActiveSessionWithReadPermissions:[self facebookSignupPermissions]
                                               allowLoginUI:YES
                                          completionHandler:
             ^(FBSession *session, FBSessionState state, NSError *error) {
                 [self facebookSessionStateChanged:session state:state error:error password:password action:action success:success failure:failure];
             }];
        }
    }
}

- (NSArray*) facebookSignupPermissions {
    return @[@"public_profile", @"user_friends", @"email"];
}

- (void) facebookSessionStateChanged:(FBSession*)session state:(FBSessionState)state error:(NSError*)error password:(NSString*)password action:(enum AuthenticationActionType)action success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response, NSString* message, BOOL displayFeedback))failure {
    
    if (!error && state == FBSessionStateOpen) {
        // If the session was opened successfully
        //NSLog(@"[AccountManager] Facebook session opened");
        [self facebookUserLoggedIn:action password:password isRecursive:NO success:success failure:failure];
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
                    failure(AuthenticationResponseFacebookUserCancelled, nil, YES);
                }
                [self doLogout];
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
                [self doLogout];
            }
        }
    }
    else {
        if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed) {
            NSLog(@"[AccountManager] Facebook session closed");
            [self doLogout];
        }
        if (failure) {
            failure(AuthenticationResponseGenericError, nil, YES);
        }
    }
}

- (void) facebookUserLoggedIn:(enum AuthenticationActionType)action password:(NSString*)password isRecursive:(BOOL)isRecursive success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response, NSString* message, BOOL displayFeedback))failure {
    
    NSLog(@"[AccountManager] facebookUserLoggedIn");
    
    // Check we got the permissions we need
    [FBRequestConnection startWithGraphPath:@"/me/permissions"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error){
                                  
                                  // These are the current permissions the user has:
                                  NSArray *currentPermissionsArray = (NSArray *)[result data];
                                  NSMutableSet *grantedPermissions = [NSMutableSet setWithCapacity:currentPermissionsArray.count];
                                  for (NSDictionary *dictionary in currentPermissionsArray) {
                                      NSString *permission = [dictionary objectForKey:@"permission"];
                                      NSString *status = [dictionary objectForKey:@"status"];
                                      if ([@"granted" isEqualToString:status]) {
                                          [grantedPermissions addObject:permission];
                                      }
                                  }
                                  
                                  // We will store the missing permissions we will have to request
                                  NSMutableArray *requestPermissions = [NSMutableArray array];
                                  NSArray *permissionsNeeded = [self facebookSignupPermissions];
                                  
                                  // Check if all the permissions we need are present in the user's current permissions
                                  // If they are not present add them to the permissions to be requested
                                  for (NSString *permission in permissionsNeeded) {
                                      if (![grantedPermissions containsObject:permission]) {
                                          [requestPermissions addObject:permission];
                                      }
                                  }

                                  if ([requestPermissions count] > 0) {

                                      NSLog(@"[AccountManager] Missing permissions: %@", requestPermissions);

                                      if (action != AuthenticationActionRefresh && !isRecursive) {
                                      
                                          // Ask for the missing permissions
                                          [FBSession.activeSession requestNewReadPermissions:requestPermissions completionHandler:^(FBSession *session, NSError *error) {
                                              
                                              if (!error) {
                                                  // Permission granted
                                                  //NSLog(@"[AccountManager] New permissions granted %@", [FBSession.activeSession permissions]);
                                                  [self facebookUserLoggedIn:action password:password isRecursive:YES success:success failure:failure];
                                              } else {
                                                  NSLog(@"[AccountManager] Failure requesting permissions");
                                                  failure(AuthenticationResponseFacebookMissingPermission, nil, YES);
                                              }
                                          }];
                                      }
                                      else {
                                          failure(AuthenticationResponseFacebookMissingPermission, nil, YES);
                                      }
                                  } else {
                                      NSLog(@"[AccountManager] Has all permissions");
                                      
                                      NSDictionary *metaInfo = @{@"metaMethod":@"facebookUserLoggedIn", @"metaAppAction":[self actionToString:action], @"metaCurrentPermissions":[[[NSString stringWithFormat:@"%@", currentPermissionsArray] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""]};

                                      [self facebookUserFetchInfo:action password:password metaInfo:metaInfo success:success failure:failure];
                                  }
                              } else {
                                  NSLog(@"[AccountManager] Failure calling /me/permissions: %@", error);
                                  failure(AuthenticationResponseGenericError, nil, YES);
                              }
                          }];
}

- (void) facebookUserFetchInfo:(enum AuthenticationActionType)action password:(NSString*)password metaInfo:(NSDictionary*)metaInfo success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response, NSString* message, BOOL displayFeedback))failure {
    
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

            [self registerUser:action email:email passwordHash:passwordHash facebookId:facebookUserId facebookAccessToken:facebookAccessToken firstName:firstName lastName:lastName gender:gender verified:verified metaInfo:metaInfo success:success failure:^(enum AuthenticationResponseType response) {
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

- (void) registerUser:(enum AuthenticationActionType)action email:(NSString*)email passwordHash:(NSString*)passwordHash facebookId:(NSString*)facebookId facebookAccessToken:(NSString*)facebookAccessToken firstName:(NSString*)firstName lastName:(NSString*)lastName gender:(NSNumber*)gender verified:(NSNumber*)verified metaInfo:(NSDictionary*)metaInfo success:(void(^)(enum AuthenticationResponseType response))success failure:(void(^)(enum AuthenticationResponseType response))failure {
    
    NSString *serverAction = [self actionToString:(action == AuthenticationActionRefresh) ? AuthenticationActionLogin : action];
    
    [[ServerUploadManager sharedInstance] registerUser:serverAction email:email passwordHash:passwordHash facebookId:facebookId facebookAccessToken:facebookAccessToken firstName:firstName lastName:lastName gender:gender verified:verified metaInfo:metaInfo retry:3 success:^(NSString *status, id responseObject) {
        
        enum AuthenticationResponseType authResponse = [self stringToAuthenticationResponse:status];
        
        if (authResponse == AuthenticationResponsePaired || authResponse == AuthenticationResponseCreated) {
            
            [self setAuthenticationState:AuthenticationStateLoggedIn];
            
            NSNumber *userId = [responseObject objectForKey:@"userId"];
            if (userId && ![userId isEqual:[NSNull null]] && !isnan([userId longLongValue]) && ([userId longLongValue] > 0)) {
                [Property setAsLongLong:userId forKey:KEY_USER_ID];
            }
            
            NSString *email = [responseObject objectForKey:@"email"];
            if (email && ![email isEqual:[NSNull null]] && email.length > 0) {
                [Property setAsString:email forKey:KEY_EMAIL];
            }
            
            NSString *firstName = [responseObject objectForKey:@"firstName"];
            if (firstName && ![firstName isEqual:[NSNull null]] && firstName.length > 0) {
                [Property setAsString:firstName forKey:KEY_FIRST_NAME];
            }
            
            NSString *lastName = [responseObject objectForKey:@"lastName"];
            if (lastName && ![lastName isEqual:[NSNull null]] && lastName.length > 0) {
                [Property setAsString:lastName forKey:KEY_LAST_NAME];
            }
            
            NSNumber *hasWindMeter = [responseObject objectForKey:@"hasWindMeter"];
            if (hasWindMeter && ![hasWindMeter isEqual:[NSNull null]]) {
                [Property setAsBoolean:([hasWindMeter integerValue] == 1) forKey:KEY_USER_HAS_WIND_METER];
            }
            
            NSNumber *creationTimeMillis = [responseObject objectForKey:@"creationTime"];
            if (creationTimeMillis) {
                NSDate *creationTime = [NSDate dateWithTimeIntervalSince1970:([creationTimeMillis doubleValue] / 1000.0)];
                [Property setAsDate:creationTime forKey:KEY_CREATION_TIME];
            }
            
            // indentify in Mixpanel and possibly create alias
            if ([Property isMixpanelEnabled]) {
                Mixpanel *mixpanel = [Mixpanel sharedInstance];

                // track Mixpanel event
                if (authResponse == AuthenticationResponseCreated) {
                    NSString *enableFacebookDisclaimerString = [Property getAsBoolean:KEY_ENABLE_FACEBOOK_DISCLAIMER] ? @"true" : @"false";
                    [mixpanel track:@"Signup" properties:@{@"Method": (facebookId ? @"Facebook" : @"Password"), @"Enable Facebook Disclaimer" : enableFacebookDisclaimerString}];
                }
                else if (action != AuthenticationActionRefresh) {
                    [mixpanel track:@"Login" properties:@{@"Method": (facebookId ? @"Facebook" : @"Password")}];
                }

                // set Mixpanel identity
                if (authResponse == AuthenticationResponseCreated) {
                    [mixpanel createAlias:[userId stringValue] forDistinctID:mixpanel.distinctId];
                }
                [mixpanel identify:[userId stringValue]];

                // register Mixpanel super properties
                [mixpanel registerSuperProperties:@{@"User": @"true", @"Creation Time": [MixpanelUtil toUTFDateString:[Property getAsDate:KEY_CREATION_TIME]]}];
                if (facebookId) {
                    [mixpanel registerSuperProperties:@{@"Facebook": @"true"}];
                }
                
                [MixpanelUtil registerUserAsMixpanelProfile];
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

- (void) doLogout {
    
    NSLog(@"[AccountManager] doLogout");
    if (isDoingLogout) {
        return;
    }
    isDoingLogout = YES;

    [Property setAsString:nil forKey:KEY_EMAIL];
    [Property setAsString:nil forKey:KEY_FIRST_NAME];
    [Property setAsString:nil forKey:KEY_LAST_NAME];
    [Property setAsString:nil forKey:KEY_USER_ID];
    [Property setAsString:nil forKey:KEY_FACEBOOK_USER_ID];
    [Property setAsString:nil forKey:KEY_FACEBOOK_ACCESS_TOKEN];
    [Property setAsString:nil forKey:KEY_AUTH_TOKEN];
    [Property setAsString:[UUIDUtil generateUUID] forKey:KEY_DEVICE_UUID];
    [Property setAsDate:[NSDate date] forKey:KEY_CREATION_TIME];
    [Property setAsString:nil forKey:KEY_USER_HAS_WIND_METER];
    [Property setAsString:nil forKey:KEY_MAP_HOURS];
    [Property setAsBoolean:NO forKey:KEY_HAS_SEEN_INTRO_FLOW];
    [Property setAsBoolean:NO forKey:KEY_MAP_GUIDE_MARKER_SHOWN];
    [Property setAsBoolean:NO forKey:KEY_MAP_GUIDE_TIME_INTERVAL_SHOWN];
    [Property setAsBoolean:NO forKey:KEY_MAP_GUIDE_ZOOM_SHOWN];
    [Property setAsBoolean:YES forKey:KEY_ENABLE_SHARE_DIALOG];
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

    if ([Property isMixpanelEnabled]) {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel reset];
        [mixpanel identify:[Property getAsString:KEY_DEVICE_UUID]];
    }

    // delete all measurement sessions
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        [MeasurementSession MR_deleteAllMatchingPredicate:[NSPredicate predicateWithValue:YES] inContext:localContext];
    }];

    [[ServerUploadManager sharedInstance] registerDevice:3];
}

- (BOOL) isLoggedIn {
    return [self getAuthenticationState] == AuthenticationStateLoggedIn;
}

- (void) setAuthenticationState:(enum AuthenticationStateType)state {
    [Property setAsInteger:[NSNumber numberWithInt:state] forKey:KEY_AUTHENTICATION_STATE];
}

- (enum AuthenticationStateType) getAuthenticationState {
    NSNumber *authState = [Property getAsInteger:KEY_AUTHENTICATION_STATE];
    if (!authState) {
        return AuthenticationStateNeverLoggedIn;
    }
    else {
        return [authState integerValue];
    }
}

- (NSString*) actionToString:(enum AuthenticationActionType)action {
    switch (action) {
        case AuthenticationActionLogin:
            return @"LOGIN";
        case AuthenticationActionSignup:
            return @"SIGNUP";
        case AuthenticationActionRefresh:
            return @"REFRESH";
    }
}

- (enum AuthenticationResponseType) stringToAuthenticationResponse:(NSString*)response {
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

- (void) ensureSharingPermissions:(void(^)())success failure:(void(^)())failure {
    
    NSArray *permissionsNeeded = @[@"publish_actions"];
    
    if ([FBSession activeSession].isOpen) {

        // Request the permissions the user currently has
        [FBRequestConnection startWithGraphPath:@"/me/permissions"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                  if (!error) {

                                      // These are the current permissions the user has:
                                      NSArray *currentPermissionsArray = (NSArray *)[result data];
                                      NSMutableSet *grantedPermissions = [NSMutableSet setWithCapacity:currentPermissionsArray.count];
                                      for (NSDictionary *dictionary in currentPermissionsArray) {
                                          NSString *permission = [dictionary objectForKey:@"permission"];
                                          NSString *status = [dictionary objectForKey:@"status"];
                                          if ([@"granted" isEqualToString:status]) {
                                              [grantedPermissions addObject:permission];
                                          }
                                      }
                                      
                                      // We will store the missing permissions we will have to request
                                      NSMutableArray *requestPermissions = [NSMutableArray array];
                                      
                                      // Check if all the permissions we need are present in the user's current permissions
                                      // If they are not present add them to the permissions to be requested
                                      for (NSString *permission in permissionsNeeded) {
                                          if (![grantedPermissions containsObject:permission]) {
                                              [requestPermissions addObject:permission];
                                          }
                                      }

                                      // If we have permissions to request
                                      if ([requestPermissions count] > 0) {
                                          [self promptForSharingPermissions:requestPermissions success:success failure:failure];
                                      } else {
                                          success();
                                      }

                                  } else {
                                      NSLog(@"[AccountManager] Failure calling /me/permissions: %@", error);
                                      failure();
                                  }
                              }];
    }
    else {
        //[self promptForSharingPermissions:permissionsNeeded success:success failure:failure];
        [FBSession openActiveSessionWithPublishPermissions:permissionsNeeded defaultAudience:FBSessionDefaultAudienceEveryone allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {

            if (!error) {
                // Permission granted
                NSLog(@"[AccountManager] New permissions granted %@", [FBSession.activeSession permissions]);
                // We can request the user information
                success();
            } else {
                NSLog(@"[AccountManager] Failure requesting permissions");
                failure();
            }
        }];
    }
}

- (void) promptForSharingPermissions:(NSArray*)permissions success:(void(^)())success failure:(void(^)())failure {
    
    
    //NSLog(@"[AccountManager] Current permissions: %@, request permissions: %@", grantedPermissions, requestPermissions);
    
    // Ask for the missing permissions
    [FBSession.activeSession requestNewPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceEveryone completionHandler:^(FBSession *session, NSError *error) {
        if (!error) {
            // Permission granted
            NSLog(@"[AccountManager] New permissions granted %@", [FBSession.activeSession permissions]);
            // We can request the user information
            success();
        } else {
            NSLog(@"[AccountManager] Failure requesting permissions");
            failure();
        }
    }];
}

@end
