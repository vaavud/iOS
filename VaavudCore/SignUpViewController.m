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
#import "vaavudAppDelegate.h"
#import "UUIDUtil.h"
#import <FacebookSDK/FacebookSDK.h>

@interface SignUpViewController ()

@property (nonatomic, weak) IBOutlet UIView *basicInputView;
@property (nonatomic, weak) IBOutlet UIButton *facebookButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet GuidedTextField *firstNameTextField;
@property (nonatomic, weak) IBOutlet GuidedTextField *lastNameTextField;
@property (nonatomic, weak) IBOutlet GuidedTextField *emailTextField;
@property (nonatomic, weak) IBOutlet GuidedTextField *passwordTextField;

@end

@implementation SignUpViewController

BOOL didShowFeedback;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.facebookButton setTitle:NSLocalizedString(@"REGISTER_BUTTON_SIGNUP_WITH_FACEBOOK", nil) forState:UIControlStateNormal];
    self.firstNameTextField.guideText = NSLocalizedString(@"REGISTER_FIELD_FIRST_NAME", nil);
    self.firstNameTextField.guidedDelegate = self;
    self.lastNameTextField.guideText = NSLocalizedString(@"REGISTER_FIELD_LAST_NAME", nil);
    self.lastNameTextField.guidedDelegate = self;
    self.emailTextField.guideText = NSLocalizedString(@"REGISTER_FIELD_EMAIL", nil);
    self.emailTextField.guidedDelegate = self;
    self.passwordTextField.guideText = NSLocalizedString(@"REGISTER_FIELD_PASSWORD", nil);
    self.passwordTextField.guidedDelegate = self;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"REGISTER_BUTTON_CREATE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPushed)];

    self.basicInputView.layer.cornerRadius = FORM_CORNER_RADIUS;
    self.basicInputView.layer.masksToBounds = YES;

    self.facebookButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.facebookButton.layer.masksToBounds = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    vaavudAppDelegate *appDelegate = (vaavudAppDelegate*) [UIApplication sharedApplication].delegate;
    appDelegate.facebookAuthenticationDelegate = nil;
}

- (void)doneButtonPushed {

    if (!self.firstNameTextField.text || self.firstNameTextField.text.length == 0) {
        [self.firstNameTextField becomeFirstResponder];
        [self showMessage:NSLocalizedString(@"REGISTER_CREATE_FEEDBACK_FIRST_NAME_EMPTY_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_CREATE_FEEDBACK_FIRST_NAME_EMPTY_TITLE", nil)];
        return;
    }

    if (!self.emailTextField.text || self.emailTextField.text.length == 0) {
        [self.emailTextField becomeFirstResponder];
        [self showMessage:NSLocalizedString(@"REGISTER_CREATE_FEEDBACK_EMAIL_EMPTY_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_CREATE_FEEDBACK_EMAIL_EMPTY_TITLE", nil)];
        return;
    }
    
    if (!self.passwordTextField.text || self.passwordTextField.text.length < 4) {
        [self.passwordTextField becomeFirstResponder];
        [self showMessage:NSLocalizedString(@"REGISTER_CREATE_FEEDBACK_PASSWORD_SHORT_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_CREATE_FEEDBACK_PASSWORD_SHORT_TITLE", nil)];
        return;
    }

    NSString *passwordHash = [PasswordUtil createHash:self.passwordTextField.text salt:self.emailTextField.text];
    NSLog(@"passwordHash=%@", passwordHash);
    
    [[ServerUploadManager sharedInstance] registerUser:@"SIGNUP" email:self.emailTextField.text passwordHash:passwordHash facebookId:nil facebookAccessToken:nil firstName:self.firstNameTextField.text lastName:self.lastNameTextField.text gender:nil verified:[NSNumber numberWithInt:0] retry:3 success:^(NSString *status) {

        if ([@"PAIRED" isEqualToString:status] || [@"CREATED" isEqualToString:status]) {
            
            [Property setAuthenticationStatus:AuthenticationStatusLoggedIn];

            if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
                RegisterNavigationController *registerNavigationController = (RegisterNavigationController*) self.navigationController;
                if (registerNavigationController.registerDelegate) {
                    [registerNavigationController.registerDelegate userAuthenticated];
                }
            }
        }
        else if ([@"INVALID_CREDENTIALS" isEqualToString:status]) {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_INVALID_CREDENTIALS_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_INVALID_CREDENTIALS_TITLE", nil)];
        }
        else if ([@"MALFORMED_EMAIL" isEqualToString:status]) {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_MALFORMED_EMAIL_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_MALFORMED_EMAIL_TITLE", nil)];
        }
        else {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_TITLE", nil)];
        }
    } failure:^(NSError *error) {
        NSLog(@"[SignUpViewController] error registering user");
        [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_TITLE", nil)];
    }];
}

- (IBAction)facebookButtonPushed:(id)sender {
    
    [self.activityIndicator startAnimating];
    [self.facebookButton setTitle:@"" forState:UIControlStateNormal];

    didShowFeedback = NO;
    vaavudAppDelegate *appDelegate = (vaavudAppDelegate*) [UIApplication sharedApplication].delegate;
    appDelegate.facebookAuthenticationDelegate = self;
    [appDelegate openFacebookSession:@"SIGNUP"];
}

- (void) facebookAuthenticationSuccess:(NSString*)status {

    [self.activityIndicator stopAnimating];
    [self.facebookButton setTitle:NSLocalizedString(@"REGISTER_BUTTON_SIGNUP_WITH_FACEBOOK", nil) forState:UIControlStateNormal];
    
    if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
        RegisterNavigationController *registerNavigationController = (RegisterNavigationController*) self.navigationController;
        if (registerNavigationController.registerDelegate) {
            [registerNavigationController.registerDelegate userAuthenticated];
        }
    }
}

- (void) facebookAuthenticationFailure:(NSString*)status message:(NSString*)message displayFeedback:(BOOL)displayFeedback {

    NSLog(@"[SignUpViewController] error registering user");
    
    [self.activityIndicator stopAnimating];
    [self.facebookButton setTitle:NSLocalizedString(@"REGISTER_BUTTON_SIGNUP_WITH_FACEBOOK", nil) forState:UIControlStateNormal];
    
    if (displayFeedback && !didShowFeedback) {
        didShowFeedback = YES;
        if (!message || message.length == 0) {
            message = NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_MESSAGE", nil);
        }
        [self showMessage:message withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_TITLE", nil)];
    }
}

- (void)showMessage:(NSString *)text withTitle:(NSString *)title {
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                      otherButtonTitles:nil] show];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.firstNameTextField) {
        [self.lastNameTextField becomeFirstResponder];
    }
    else if (textField == self.lastNameTextField) {
        [self.emailTextField becomeFirstResponder];
    }
    else if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (textField == self.passwordTextField) {
        [self doneButtonPushed];
    }
    return YES;
}

@end
