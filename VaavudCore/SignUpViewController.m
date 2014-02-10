//
//  SignUpViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 07/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "SignUpViewController.h"
#import "GuidedTextField.h"

@interface SignUpViewController ()

@property (nonatomic, weak) IBOutlet UIView *basicInputView;
@property (nonatomic, weak) IBOutlet UIButton *facebookButton;
@property (nonatomic, weak) IBOutlet GuidedTextField *firstNameTextField;
@property (nonatomic, weak) IBOutlet GuidedTextField *lastNameTextField;
@property (nonatomic, weak) IBOutlet GuidedTextField *emailTextField;
@property (nonatomic, weak) IBOutlet GuidedTextField *passwordTextField;

@end

@implementation SignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.facebookButton setTitle:NSLocalizedString(@"REGISTER_SIGNUP_WITH_FACEBOOK", nil) forState:UIControlStateNormal];
    self.firstNameTextField.guideText = NSLocalizedString(@"REGISTER_FIRST_NAME", nil);
    self.lastNameTextField.guideText = NSLocalizedString(@"REGISTER_LAST_NAME", nil);
    self.emailTextField.guideText = NSLocalizedString(@"REGISTER_EMAIL", nil);
    self.passwordTextField.guideText = NSLocalizedString(@"REGISTER_PASSWORD", nil);
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"REGISTER_CREATE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPushed)];

    self.basicInputView.layer.cornerRadius = CORNER_RADIUS;
    self.basicInputView.layer.masksToBounds = YES;

    self.facebookButton.layer.cornerRadius = CORNER_RADIUS;
    self.facebookButton.layer.masksToBounds = YES;    
}

- (void)doneButtonPushed {
    
}

@end
