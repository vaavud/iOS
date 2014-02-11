//
//  SignUpViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 07/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "SignUpViewController.h"
#import "GuidedTextField.h"
#import "PasswordUtil.h"
#import "ServerUploadManager.h"
#import "Property+Util.h"
#import "RegisterNavigationController.h"

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

    if (!self.emailTextField.text || self.emailTextField.text.length == 0) {
        [self showMessage:NSLocalizedString(@"REGISTER_FORM_EMAIL_EMPTY_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FORM_EMAIL_EMPTY_TITLE", nil)];
        return;
    }

    // TODO: validate email format
    
    if (!self.passwordTextField.text || self.passwordTextField.text.length < 4) {
        [self showMessage:NSLocalizedString(@"REGISTER_FORM_PASSWORD_SHORT_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FORM_PASSWORD_SHORT_TITLE", nil)];
        return;
    }

    if (!self.firstNameTextField.text || self.firstNameTextField.text.length == 0) {
        [self showMessage:NSLocalizedString(@"REGISTER_FORM_FIRST_NAME_EMPTY_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FORM_FIRST_NAME_EMPTY_TITLE", nil)];
        return;
    }

    NSString *passwordHash = [PasswordUtil createHash:self.passwordTextField.text salt:self.emailTextField.text];
    NSLog(@"passwordHash=%@", passwordHash);
    
    [[ServerUploadManager sharedInstance] registerUser:self.emailTextField.text passwordHash:passwordHash facebookId:nil facebookAccessToken:nil firstName:self.firstNameTextField.text lastName:self.lastNameTextField.text retry:3 success:^(NSString *status) {

        if ([@"PAIRED" isEqualToString:status] || [@"CREATED" isEqualToString:status]) {
            
            [Property setAsString:self.emailTextField.text forKey:KEY_EMAIL];
            [Property setAsBoolean:YES forKey:KEY_LOGGED_IN];

            if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
                RegisterNavigationController *registerNavigationController = (RegisterNavigationController*) self.navigationController;
                if (registerNavigationController.registerDelegate) {
                    [registerNavigationController.registerDelegate userAuthenticated];
                }
            }
        }
        else {
            [self showMessage:NSLocalizedString(@"REGISTER_INVALID_CREDENTIALS_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_INVALID_CREDENTIALS_TITLE", nil)];
        }
    } failure:^(NSError *error) {
        NSLog(@"[SignUpViewController] error registering user");
        [self showMessage:NSLocalizedString(@"REGISTER_ERROR_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_ERROR_TITLE", nil)];
    }];
}

- (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:self
                      cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                      otherButtonTitles:nil] show];
}


@end
