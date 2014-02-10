//
//  LoginRootViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 07/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "LoginRootViewController.h"

@interface LoginRootViewController ()

@property (nonatomic, weak) IBOutlet UIButton *signUpButton;
@property (nonatomic, weak) IBOutlet UIButton *logInButton;

@end

@implementation LoginRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"HISTORY_TITLE", nil);
    
    self.signUpButton.layer.cornerRadius = CORNER_RADIUS;
    self.signUpButton.layer.masksToBounds = YES;

    self.logInButton.layer.cornerRadius = CORNER_RADIUS;
    self.logInButton.layer.masksToBounds = YES;
}

@end
