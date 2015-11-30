//
//  RegisterNavigationViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "RegisterNavigationController.h"
#import "RLogInViewController.h"
#import "RegisterViewController.h"

@implementation RegisterNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    if (self.startScreen && self.startScreen > 0) {
        if (self.startScreen == RegisterScreenTypeLogIn) {
            RLogInViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"LogInViewController"];
            loginViewController.completion = self.completion;
            [self setViewControllers:@[loginViewController] animated:NO];
        }
        else if (self.startScreen == RegisterScreenTypeSignUp) {
            RegisterViewController *registerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SignUpViewController"];
            registerViewController.completion = self.completion;
            [self setViewControllers:@[registerViewController] animated:NO];
        }
    }
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end

@implementation RotatableNavigationController

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
