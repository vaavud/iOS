//
//  vaavudAppDelegate.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "vaavudAppDelegate.h"
#import "TestFlight.h"
#import "GAI.h"
#import "ModelManager.h"
#import "ServerUploadManager.h"
#import "LocationManager.h"
#import "QueryStringUtil.h"
#import "TabBarController.h"
#import "TMCache.h"
#import "Property+Util.h"

@implementation vaavudAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [TestFlight takeOff:@"1b4310d3-6215-4ff5-a881-dd67a6d7ab91"];
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-38878667-2"];
    
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4*1024*1024 diskCapacity:20*1024*1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    
    TMCache *cache = [TMCache sharedCache];
    cache.diskCache.ageLimit = 24.0 * 3600.0;
    
    [MagicalRecord setupAutoMigratingCoreDataStack];
    [[ModelManager sharedInstance] initializeModel];
    [[ServerUploadManager sharedInstance] start];
    [[LocationManager sharedInstance] start];
    
    self.xCallbackSuccess = nil;
        
    // TODO: REMOVE THIS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    [Property setAsBoolean:NO forKey:KEY_LOGGED_IN];

    // Whenever a person opens the app, check for a cached session
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        NSLog(@"[VaavudAppDelegate] Found a cached Facebook session");

        // If there's one, just open the session silently, without showing the user the login UI
        [FBSession openActiveSessionWithReadPermissions:[self facebookSignupPermissions]
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                          [self facebookSessionStateChanged:session state:state error:error action:@"LOGIN"];
                                      }];
    }

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBAppCall handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    if ([url.scheme isEqualToString:@"vaavud"]) {
        NSLog(@"url recieved: %@", url);
        NSLog(@"query string: %@", [url query]);
        NSLog(@"host: %@", [url host]);
        NSLog(@"url path: %@", [url path]);
        NSDictionary *dict = [QueryStringUtil parseQueryString:[url query]];
        NSLog(@"query dict: %@", dict);
        
        self.xCallbackSuccess = nil;
        
        if ([@"x-callback-url" compare:[url host]] == NSOrderedSame && [@"/measure" compare:[url path]] == NSOrderedSame) {
            NSString* xSuccess = [dict objectForKey:@"x-success"];
            if (xSuccess && xSuccess != nil && xSuccess != (id)[NSNull null] && [xSuccess length] > 0) {
                NSLog(@"[VaavudAppDelegate] opened with x-callback-url, setting x-success to %@", xSuccess);
                self.xCallbackSuccess = xSuccess;
                
                TabBarController *tabBarController = (TabBarController*) self.window.rootViewController;
                if (tabBarController && tabBarController != nil && tabBarController.isViewLoaded) {
                    tabBarController.selectedIndex = 0;
                }
            }
        }
    }
    else {
        return [FBSession.activeSession handleOpenURL:url];
    }
    
    return YES;
}

- (void)openFacebookSession:(NSString*)action {
    
    [FBSession openActiveSessionWithReadPermissions:[self facebookSignupPermissions]
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         [self facebookSessionStateChanged:session state:state error:error action:action];
     }];
}

- (void)facebookSessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error action:(NSString*)action {

    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen) {
        NSLog(@"[VaavudAppDelegate] Facebook session opened");
        [self facebookUserLoggedIn:action];
        return;
    }
    
    // Handle errors
    if (error) {
        
        BOOL hasCalledDelegate = NO;
        
        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES) {
            if (self.facebookAuthenticationDelegate) {
                [self.facebookAuthenticationDelegate facebookAuthenticationFailure:nil message:[FBErrorUtility userMessageForError:error] displayFeedback:YES];
                hasCalledDelegate = YES;
            }
        }
        else {
            FBErrorCategory errorCategory = [FBErrorUtility errorCategoryForError:error];
            
            // If the user cancelled login, do nothing
            if (errorCategory == FBErrorCategoryUserCancelled) {
                NSLog(@"[VaavudAppDelegate] Facebook user cancelled login");
                if (self.facebookAuthenticationDelegate) {
                    [self.facebookAuthenticationDelegate facebookAuthenticationFailure:nil message:nil displayFeedback:NO];
                    hasCalledDelegate = YES;
                }
            }
            else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
                NSLog(@"[VaavudAppDelegate] Facebook authentication reopen session");
                // TODO: we should probably show the login screen here?
            }
            else {
                NSLog(@"[VaavudAppDelegate] Facebook error %d", errorCategory);
                if (self.facebookAuthenticationDelegate) {
                    [self.facebookAuthenticationDelegate facebookAuthenticationFailure:nil message:nil displayFeedback:YES];
                    hasCalledDelegate = YES;
                }
            }
        }

        // Clear this token
        [FBSession.activeSession closeAndClearTokenInformation];
        [self facebookUserLoggedOut];
        if (!hasCalledDelegate && self.facebookAuthenticationDelegate) {
            [self.facebookAuthenticationDelegate facebookAuthenticationFailure:nil message:nil displayFeedback:YES];
        }
    }
    else {
        if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed) {
            NSLog(@"[VaavudAppDelegate] Facebook session closed");
            [self facebookUserLoggedOut];
        }
        if (self.facebookAuthenticationDelegate) {
            [self.facebookAuthenticationDelegate facebookAuthenticationFailure:nil message:nil displayFeedback:YES];
        }
    }
}

- (void)facebookUserLoggedOut {
    NSLog(@"[VaavudAppDelegate] facebookUserLoggedOut");
    [Property setAsString:nil forKey:KEY_FACEBOOK_ACCESS_TOKEN];
    [Property setAsBoolean:NO forKey:KEY_LOGGED_IN];
}

- (void)facebookUserLoggedIn:(NSString*)action {
    NSLog(@"[VaavudAppDelegate] facebookUserLoggedIn");
    
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
            
            NSLog(@"Facebook logged in - facebookUserId=%@, accessToken=%@, email=%@, firstName=%@, lastName=%@, gender=%@, verified=%@", facebookUserId, facebookAccessToken, email, firstName, lastName, gender, verified);
            
            [[ServerUploadManager sharedInstance] registerUser:action email:email passwordHash:nil facebookId:facebookUserId facebookAccessToken:facebookAccessToken firstName:firstName lastName:lastName gender:gender verified:verified retry:3 success:^(NSString *status) {
                
                if ([@"PAIRED" isEqualToString:status] || [@"CREATED" isEqualToString:status]) {
                    [Property setAsBoolean:YES forKey:KEY_LOGGED_IN];
                    if (self.facebookAuthenticationDelegate) {
                        [self.facebookAuthenticationDelegate facebookAuthenticationSuccess:status];
                    }
                }
                else {
                    if (self.facebookAuthenticationDelegate) {
                        [self.facebookAuthenticationDelegate facebookAuthenticationFailure:status message:nil displayFeedback:YES];
                    }
                }
            } failure:^(NSError *error) {
                if (self.facebookAuthenticationDelegate) {
                    [self.facebookAuthenticationDelegate facebookAuthenticationFailure:nil message:nil displayFeedback:YES];
                }
            }];
        }
        else {
            if (self.facebookAuthenticationDelegate) {
                [self.facebookAuthenticationDelegate facebookAuthenticationFailure:nil message:nil displayFeedback:YES];
            }
        }
    }];
}

- (NSArray*) facebookSignupPermissions {
    return @[@"basic_info", @"email"];
}

@end
