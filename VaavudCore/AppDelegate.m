//
//  vaavudAppDelegate.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "AppDelegate.h"
#import "TestFlight.h"
#import "ModelManager.h"
#import "ServerUploadManager.h"
#import "LocationManager.h"
#import "QueryStringUtil.h"
#import "TabBarController.h"
#import "TMCache.h"
#import "AccountManager.h"
#import "Mixpanel.h"
#import "Property+Util.h"
#import "UnitUtil.h"
#import "UIColor+VaavudColors.h"
#import "MixpanelUtil.h"

@interface AppDelegate()

@property (nonatomic, strong) NSDate *lastAppActive;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    //NSLog(@"[AppDelegate] didFinishLaunchingWithOptions");
    
    [TestFlight takeOff:[[NSString alloc] initWithCString:MACRO_VALUE(TESTFLIGHT_TOKEN) encoding:NSASCIIStringEncoding]];

    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4*1024*1024 diskCapacity:20*1024*1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    
    TMCache *cache = [TMCache sharedCache];
    cache.diskCache.ageLimit = 24.0 * 3600.0;
    
    [MagicalRecord setupAutoMigratingCoreDataStack];
    [[ModelManager sharedInstance] initializeModel];
    [[ServerUploadManager sharedInstance] start];
    [[LocationManager sharedInstance] startIfEnabled];
    //[FBSettings setLoggingBehavior:[NSSet setWithObjects:FBLoggingBehaviorFBRequests, FBLoggingBehaviorInformational, nil]];
    
    self.xCallbackSuccess = nil;

    if ([Property isMixpanelEnabled]) {
        [Mixpanel sharedInstanceWithToken:@"757f6311d315f94cdfc8d16fb4d973c0"];

        // if logged in, make sure Mixpanel knows the Vaavud user ID
        if ([[AccountManager sharedInstance] isLoggedIn] && [Property getAsString:KEY_USER_ID]) {
            [[Mixpanel sharedInstance] identify:[Property getAsString:KEY_USER_ID]];
        }
    }

    // Whenever a person opens the app, check for a cached session and refresh token
    if ([[AccountManager sharedInstance] isLoggedIn]) {
        [[AccountManager sharedInstance] registerWithFacebook:nil action:AuthenticationActionRefresh];
    }
    
    // set has wind meter property if not set
    if (![Property getAsString:KEY_USER_HAS_WIND_METER]) {
        [Property refreshHasWindMeter];
    }

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UIViewController *viewController = nil;
    
#ifdef AGRI
    
    // AGRICULTURE APP
    
    if ([self.window respondsToSelector:@selector(setTintColor:)]) {
        UIColor *vaavudColor = [UIColor vaavudColor];
        self.window.tintColor = vaavudColor;
        [[UINavigationBar appearance] setTintColor:vaavudColor];
    }
    
    if ([[AccountManager sharedInstance] isLoggedIn]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Agriculture" bundle:nil];
        viewController = [storyboard instantiateViewControllerWithIdentifier:@"AgriTabBarController"];
    }
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Agriculture" bundle:nil];
        viewController = [storyboard instantiateViewControllerWithIdentifier:@"AgriLoginViewController"];
    }

#elif CORE
    
    // CORE VAAVUD APP
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    NSString *vcName;
    
    if ([Property getAsBoolean:KEY_HAS_SEEN_INTRO_FLOW defaultValue:NO]) {
        // Not a new user
        NSLog(@"KEY_HAS_SEEN_INTRO_FLOW");

        if ([Property getAsBoolean:KEY_HAS_SEEN_UPGRADE_FLOW defaultValue:NO]) {
            // Has seen upgrade flow
            NSLog(@"KEY_HAS_SEEN_UPGRADE_FLOW");
            vcName = @"TabBarController";
        }
        else {
            // Has not seen upgrade flow
            NSLog(@"not KEY_HAS_SEEN_UPGRADE_FLOW");
            vcName = @"UpgradingUserViewController";
        }
    }
    else {
        // Has not seen intro flow so we will show it now
        NSLog(@"not KEY_HAS_SEEN_INTRO_FLOW");

        // No need to ever show upgrade flow
        [Property setAsBoolean:YES forKey:KEY_HAS_SEEN_UPGRADE_FLOW];
        vcName = @"FirstTimeFlowController";
    }
    
//    vcName = @"UpgradingUserViewController"; // FIXME: Remove this

    viewController = [storyboard instantiateViewControllerWithIdentifier:vcName];

#endif
    
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActive];
    
    if ([Property isMixpanelEnabled]) {
        
        [MixpanelUtil registerUserAsMixpanelProfile];
        [MixpanelUtil updateMeasurementProperties:YES];

        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        
        // Mixpanel super properties
        NSDate *creationTime = [Property getAsDate:KEY_CREATION_TIME];
        if (creationTime) {
            [mixpanel registerSuperPropertiesOnce:@{@"Creation Time": [MixpanelUtil toUTFDateString:creationTime]}];
        }
        
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
        
        NSString *userId = [Property getAsString:KEY_USER_ID];
        if (userId) {
            [dictionary setObject:@"true" forKey:@"User"];
        }

        NSString *facebookUserId = [Property getAsString:KEY_FACEBOOK_USER_ID];
        if (facebookUserId) {
            [dictionary setObject:@"true" forKey:@"Facebook"];
        }

        NSString *language = [Property getAsString:KEY_LANGUAGE];
        if (language) {
            [dictionary setObject:language forKey:@"Language"];
        }
        
        NSNumber *windSpeedUnit = [Property getAsInteger:KEY_WIND_SPEED_UNIT];
        if (windSpeedUnit) {
            NSString *unit = [UnitUtil jsonNameForWindSpeedUnit:[windSpeedUnit intValue]];
            [dictionary setObject:unit forKey:@"Speed Unit"];
        }
        
        BOOL enableShareDialog = [Property getAsBoolean:KEY_ENABLE_SHARE_DIALOG defaultValue:YES];
        [dictionary setObject:(enableShareDialog ? @"true" : @"false") forKey:@"Enable Share Dialog"];
        
        if (dictionary.count > 0) {
            [mixpanel registerSuperProperties:dictionary];
        }
    }
    
    if (self.lastAppActive == nil || fabs([self.lastAppActive timeIntervalSinceNow]) > 30.0 * 60.0 /* 30 mins */) {
        if ([Property isMixpanelEnabled]) {
            [[Mixpanel sharedInstance] track:@"Open App"];
        }
        self.lastAppActive = [NSDate date];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

- (BOOL)application:(UIApplication*)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
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

                if ([self.window.rootViewController isKindOfClass:[TabBarController class]]) {
                    TabBarController *tabBarController = (TabBarController*) self.window.rootViewController;
                    if (tabBarController && tabBarController != nil && tabBarController.isViewLoaded) {
                        tabBarController.selectedIndex = 0;
                    }
                }
            }
        }
    }
    else {
        return [FBSession.activeSession handleOpenURL:url];
    }
    
    return YES;
}

- (void)userAuthenticated:(BOOL)isSignup viewController:(UIViewController *)viewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UIViewController *nextViewController = [storyboard instantiateViewControllerWithIdentifier:@"TabBarController"];
    //nextViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    //[viewController presentViewController:nextViewController animated:YES completion:nil];
    self.window.rootViewController = nextViewController;
    
    [[ServerUploadManager sharedInstance] syncHistory:2 ignoreGracePeriod:YES success:nil failure:nil];
}

- (void)cancelled:(UIViewController *)viewController {
}

- (NSString *)registerScreenTitle {
    return nil;
}

- (NSString *)registerTeaserText {
    return nil;
}

@end
