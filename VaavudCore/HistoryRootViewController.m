//
//  HistoryRootViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 07/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "HistoryRootViewController.h"
#import "Property+Util.h"
#import "RegisterNavigationController.h"
#import "AccountManager.h"
#import "MeasurementSession+Util.h"
#import "ServerUploadManager.h"
#import "Mixpanel.h"

// TABORT

@interface HistoryRootViewController ()

@property (nonatomic, weak) UIViewController *childViewController;

@end

@implementation HistoryRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifdef CORE
        UIImage *selectedTabImage = [[UIImage imageNamed:@"history_selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.tabBarItem.selectedImage = selectedTabImage;
#endif
}

- (void)tabSelected {
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"History Tab"];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self chooseContentController:NO];
}

- (void)userAuthenticated:(BOOL)isSignup viewController:(UIViewController *)viewController {
    [self chooseContentController:YES];
}

- (void)cancelled:(UIViewController *)viewController {
}

- (NSString *)registerScreenTitle {
    return NSLocalizedString(@"HISTORY_TITLE", nil); // LOKALISERA_BORT sedan
}

- (NSString *)registerTeaserText {
    return NSLocalizedString(@"HISTORY_REGISTER_TEASER", nil); // LOKALISERA_BORT sedan
}

- (void)chooseContentController:(BOOL)ignoreGracePeriod {
    if (ignoreGracePeriod) {
        [self syncHistory:YES];
    }
    [self chooseContentControllerWithNoHistorySync];
    if (!ignoreGracePeriod) {
        [self syncHistory:NO];
    }
}

- (void)chooseContentControllerWithNoHistorySync {
    UIViewController *newController = nil;
    
    if ([[AccountManager sharedInstance] isLoggedIn]) {
        if ([ServerUploadManager sharedInstance].isHistorySyncBusy) {
            newController = [self.storyboard instantiateViewControllerWithIdentifier:@"LoadingHistoryNavigationController"];
        }
        else {
            MeasurementSession *measurementSession = [MeasurementSession MR_findFirst];
            if (!measurementSession) {
                newController = [self.storyboard instantiateViewControllerWithIdentifier:@"NoHistoryNavigationController"];
            }
//            else if (![self.childViewController isKindOfClass:[HistoryNavigationController class]]) {
//                newController = [self.storyboard instantiateViewControllerWithIdentifier:@"HistoryNavigationController"];
//            }
        }
    }
    else if (![self.childViewController isKindOfClass:[RegisterNavigationController class]]) {
        UIStoryboard *loginStoryBoard = [UIStoryboard storyboardWithName:@"Register" bundle:nil];
        newController = [loginStoryBoard instantiateInitialViewController];
        if ([newController isKindOfClass:[RegisterNavigationController class]]) {
            ((RegisterNavigationController *)newController).registerDelegate = self;
        }
    }
    
    if (newController) {
        if (self.childViewController) {
            [self hideContentController:self.childViewController];
        }
        [self showContentController:newController];
        self.childViewController = newController;
    }
}

- (void)showContentController:(UIViewController *)viewController {
    viewController.view.frame = self.view.bounds;
    
    [self addChildViewController:viewController];
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)hideContentController:(UIViewController *)viewController {
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

- (void)syncHistory:(BOOL)ignoreGracePeriod {
    if ([[AccountManager sharedInstance] isLoggedIn]) {
        [[ServerUploadManager sharedInstance] syncHistory:2 ignoreGracePeriod:ignoreGracePeriod success:^{
            if ([self.childViewController conformsToProtocol:@protocol(HistoryLoadedListener)]) {
                id<HistoryLoadedListener> listener = (id<HistoryLoadedListener>)self.childViewController;
                [listener historyLoaded];
            }
            else if ([[AccountManager sharedInstance] isLoggedIn]) {
                [self chooseContentControllerWithNoHistorySync];
            }
        } failure:^(NSError *error) {
            //NSLog(@"[HistoryRootViewController] Got failure callback from history sync");
//            if ([self.childViewController isKindOfClass:[LoadingHistoryViewController class]]) {
//                [self chooseContentControllerWithNoHistorySync];
//            }
        }];
    }
}

@end
