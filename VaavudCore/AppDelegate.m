//
//  vaavudAppDelegate.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "AppDelegate.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "LocationManager.h"
#import "TMCache.h"
#import "Vaavud-Swift.h"
#import "Amplitude.h"
#import "FBSDKCoreKit.h"

@interface AppDelegate() <DBRestClientDelegate>

@property (nonatomic, strong) NSDate *lastAppActive;
@property (nonatomic) DropboxUploader *dropboxUploader;

@end

@implementation AppDelegate

-(BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Firebase defaultConfig].persistenceEnabled = YES;
    
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4*1024*1024 diskCapacity:20*1024*1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [application registerUserNotificationSettings:notificationSettings];
    [application registerForRemoteNotifications];
    
    TMCache *cache = [TMCache sharedCache];
    cache.diskCache.ageLimit = 24.0*3600.0;
    
    [[LocationManager sharedInstance] startIfEnabled];
    //[FBSettings setLoggingBehavior:[NSSet setWithObjects:FBLoggingBehaviorFBRequests, FBLoggingBehaviorInformational, nil]];
            
    self.xCallbackSuccess = nil;
    
    [Fabric with:@[[Crashlytics class]]];
    
    // Dropbox
    [DBSession setSharedSession:[[DBSession alloc] initWithAppKey:@"zszsy52n0svxcv7" appSecret:@"t39k1uzaxs7a0zj" root:kDBRootAppFolder]];
    
#ifdef DEBUG
    [[Amplitude instance] initializeApiKey:@"043371ecbefba51ec63a992d0cc57491"];
#else
    [[Amplitude instance] initializeApiKey:@"7a5147502033e658f1357bc04b793a2b"];
#endif
    [[Amplitude instance] enableLocationListening];
    
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  
    UIViewController *parent = [[UIViewController alloc] init];
    
    self.window.rootViewController = parent;
    
    UIViewController *vc;
    
    if (![[AuthorizationController shared] verifyAuth]) {
        UINavigationController *nav = [[UIStoryboard storyboardWithName:@"Login" bundle:nil] instantiateInitialViewController];
        UIViewController *pushed = [[UIStoryboard storyboardWithName:@"Login" bundle:nil] instantiateViewControllerWithIdentifier:@"Selector"];
        [nav pushViewController:pushed animated:NO];
        
        vc = nav;
    }
    else {
        vc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateInitialViewController];
    }

    [parent addChildViewController:vc];
    [parent.view addSubview:vc.view];
    [vc didMoveToParentViewController:parent];

    [self.window makeKeyAndVisible];
    

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
//    [FBAppCall handleDidBecomeActive];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([url.scheme isEqualToString:@"vaavud"]) {
        NSDictionary *dict = [self parseQueryString:url.query];
        
        self.xCallbackSuccess = nil;
        
        if ([url.host isEqualToString:@"x-callback-url"]) {
            if ([url.path isEqualToString:@"/measure"]) {
                self.xCallbackSuccess = [dict objectForKey:@"x-success"];
                
//                if ([self.window.rootViewController isKindOfClass:[TabBarController class]]) {
//                    TabBarController *tabBarController = (TabBarController *)self.window.rootViewController;
//                    if (tabBarController != nil && tabBarController.isViewLoaded) {
//                        [tabBarController takeMeasurementFromUrlScheme];
//                        [LogHelper logWithGroupName:@"URL-Scheme" event:@"Opened" properties:@{ @"source" : sourceApplication }];
//                    }
//                }
            }
        }
    }
    else if ([[DBSession sharedSession] handleOpenURL:url]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"dropboxIsLinked"
         object:@([[DBSession sharedSession] isLinked])];
        //return YES;
    }
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                 openURL:url
                                                       sourceApplication:sourceApplication
                                                              annotation:annotation];
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:6];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [dict setObject:val forKey:key];
    }
    return dict;
}


- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"token---%@", token);
}


- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@"Error in registration. Error: %@", err);
}


#pragma mark - Dropbox

//-(void)uploadToDropbox:(MeasurementSession *)session {
//    if (!self.dropboxUploader) {
//        self.dropboxUploader = [[DropboxUploader alloc] initWithDelegate:self];
//    }
//    
//    [self.dropboxUploader uploadToDropbox:session];
//}

//- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
//              from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
//    
//    NSError *error = nil;
//    [[NSFileManager defaultManager] removeItemAtPath:srcPath error:&error];
//    if (!error) {
//        if (LOG_OTHER) NSLog(@"File uploaded and deleted successfully to path: %@", metadata.path);
//    }
//    else {
//        if (LOG_OTHER) NSLog(@"File uploaded successfully, but not deleted to path: %@, error: %@", metadata.path, error.localizedDescription);
//    }
//}
//
//- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
//    if (LOG_OTHER) NSLog(@"File upload failed with error: %@", error);
//}

@end
