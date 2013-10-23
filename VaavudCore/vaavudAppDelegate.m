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

@implementation vaavudAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [TestFlight takeOff:@"1b4310d3-6215-4ff5-a881-dd67a6d7ab91"];
    
    [GAI sharedInstance].dispatchInterval = 20;
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-38878667-2"];
    
    [MagicalRecord setupAutoMigratingCoreDataStack];
    [[ModelManager sharedInstance] initializeModel];
    [[ServerUploadManager sharedInstance] start];
    [[LocationManager sharedInstance] start];
    self.xCallbackSuccess = nil;
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
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
        }
    }
    
    return YES;
}
@end
