//
//  LoginRootViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 07/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "RegisterViewController.h"
#import "RegisterNavigationController.h"
#import "Mixpanel.h"
#import "Property+Util.h"

@interface RegisterViewController ()

@property (nonatomic, weak) IBOutlet UILabel *teaserLabel;
@property (nonatomic, weak) IBOutlet UIButton *signUpButton;
@property (nonatomic, weak) IBOutlet UIButton *logInButton;

@end

@implementation RegisterViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
        RegisterNavigationController *registerNavigationController = (RegisterNavigationController*) self.navigationController;
        if (registerNavigationController.registerDelegate) {
            self.navigationItem.title = [registerNavigationController.registerDelegate registerScreenTitle];
            self.teaserLabel.text = [registerNavigationController.registerDelegate registerTeaserText];
        }
    }
    
    self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"BUTTON_CANCEL", nil);
    
    self.signUpButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.signUpButton.layer.masksToBounds = YES;
    [self.signUpButton setTitle:NSLocalizedString(@"REGISTER_TITLE_SIGNUP", nil) forState:UIControlStateNormal];

    self.logInButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.logInButton.layer.masksToBounds = YES;
    [self.logInButton setTitle:NSLocalizedString(@"REGISTER_TITLE_LOGIN", nil) forState:UIControlStateNormal];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Signup/Login Selection Screen"];
    }
}

@end
