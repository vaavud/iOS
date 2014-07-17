//
//  ParentViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 08/07/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "ParentViewController.h"

@interface ParentViewController ()

@property (nonatomic, weak) UIViewController *childViewController;

@end

@implementation ParentViewController

- (void) viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.delegate) {
        [self.delegate selectViewController];
    }
}

- (void) switchChildController:(UIViewController*)childViewController {
    if (childViewController && childViewController != self.childViewController) {
        if (self.childViewController) {
            [self hideChildController:self.childViewController];
        }
        [self showChildController:childViewController];
        self.childViewController = childViewController;
    }
}

- (void) showChildController:(UIViewController*)viewController {
    viewController.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    [self addChildViewController:viewController];
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void) hideChildController:(UIViewController*)viewController {
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

@end
