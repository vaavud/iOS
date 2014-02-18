//
//  HistoryRootViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 07/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "HistoryRootViewController.h"
#import "Property+Util.h"

@interface HistoryRootViewController ()

@property (nonatomic, weak) UIViewController *childViewController;

@end

@implementation HistoryRootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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
    
    if (self.childViewController) {
        [self hideContentController:self.childViewController];
    }
    
    if ([Property isLoggedIn]) {
        self.childViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"HistoryNavigationController"];
    }
    else {
        UIStoryboard *loginStoryBoard = [UIStoryboard storyboardWithName:@"Register" bundle:nil];
        self.childViewController = [loginStoryBoard instantiateInitialViewController];
        
        if ([self.childViewController isKindOfClass:[RegisterNavigationController class]]) {
            ((RegisterNavigationController*) self.childViewController).registerDelegate = self;
        }
    }
    
    [self showContentController:self.childViewController];
}

- (void)showContentController:(UIViewController*)viewController {
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
