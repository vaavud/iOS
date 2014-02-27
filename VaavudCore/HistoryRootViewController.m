//
//  HistoryRootViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 07/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "HistoryRootViewController.h"
#import "Property+Util.h"
#import "HistoryNavigationController.h"
#import "RegisterNavigationController.h"
#import "AccountManager.h"
#import "MeasurementSession+Util.h"

@interface HistoryRootViewController ()

@property (nonatomic, weak) UIViewController *childViewController;

@end

@implementation HistoryRootViewController

- (void) awakeFromNib {
    [super awakeFromNib];
    self.tabBarItem.title = NSLocalizedString(@"TAB_HISTORY", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        UIImage *selectedTabImage = [[UIImage imageNamed:@"history_selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.tabBarItem.selectedImage = selectedTabImage;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self chooseContentController];
}

- (void) userAuthenticated {
    [self chooseContentController];
}

- (NSString*) registerScreenTitle {
    return NSLocalizedString(@"HISTORY_TITLE", nil);
}

- (NSString*) registerTeaserText {
    return NSLocalizedString(@"HISTORY_REGISTER_TEASER", nil);
}

- (void) chooseContentController {
    
    UIViewController *newController = nil;
    
    MeasurementSession *measurementSession = [MeasurementSession MR_findFirst];
    if (!measurementSession) {
        newController = [self.storyboard instantiateViewControllerWithIdentifier:@"NoHistoryNavigationController"];
    }
    else if ([[AccountManager sharedInstance] isLoggedIn]) {
        if (![self.childViewController isKindOfClass:[HistoryNavigationController class]]) {
            newController = [self.storyboard instantiateViewControllerWithIdentifier:@"HistoryNavigationController"];
        }
    }
    else if (![self.childViewController isKindOfClass:[RegisterNavigationController class]]) {
        UIStoryboard *loginStoryBoard = [UIStoryboard storyboardWithName:@"Register" bundle:nil];
        newController = [loginStoryBoard instantiateInitialViewController];
        if ([newController isKindOfClass:[RegisterNavigationController class]]) {
            ((RegisterNavigationController*) newController).registerDelegate = self;
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

- (void)showContentController:(UIViewController*)viewController {
    
    viewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    
    [self addChildViewController:viewController];
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)hideContentController:(UIViewController*)viewController {
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

@end
