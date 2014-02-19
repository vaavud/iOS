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
        
    // Whenever a person opens the app, check for a cached session
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        NSLog(@"[VaavudAppDelegate] Found a cached Facebook session");

        // If there's one, just open the session silently, without showing the user the login UI
        [FBSession openActiveSessionWithReadPermissions:[AccountUtil facebookSignupPermissions]
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                          [AccountUtil facebookSessionStateChanged:session state:state error:error action:AuthenticationActionLogin success:nil failure:nil];
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

// note: the reason this method is here on the delegate is that the Facebook SDK keeps a
// reference to the completion handler provided in openActiveSessionXXX and to make sure
// that this handler doesn't contain any pointers to stuff that might have been deallocated
// we use a facebookDelegate set on the app delegate as indirection
- (void)openFacebookSession:(enum AuthenticationActionType)action {
    
    [FBSession openActiveSessionWithReadPermissions:[AccountUtil facebookSignupPermissions]
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         [AccountUtil facebookSessionStateChanged:session state:state error:error action:action success:^(enum AuthenticationResponseType response) {
             if (self.facebookAuthenticationDelegate) {
                 [self.facebookAuthenticationDelegate facebookAuthenticationSuccess:response];
             }
         } failure:^(enum AuthenticationResponseType response, NSString *message, BOOL displayFeedback) {
             if (self.facebookAuthenticationDelegate) {
                 [self.facebookAuthenticationDelegate facebookAuthenticationFailure:response message:message displayFeedback:displayFeedback];
             }
         }];
     }];
}

@end
