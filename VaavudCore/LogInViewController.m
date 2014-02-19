//
//  LogInViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 12/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "LogInViewController.h"
#import "PasswordUtil.h"
#import "ServerUploadManager.h"
#import "Property+Util.h"
#import "RegisterNavigationController.h"
#import "vaavudAppDelegate.h"
#import "AccountUtil.h"
#import <FacebookSDK/FacebookSDK.h>

@interface LogInViewController ()

@property (nonatomic, weak) IBOutlet UIView *basicInputView;
@property (nonatomic, weak) IBOutlet UIButton *facebookButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet GuidedTextField *emailTextField;
@property (nonatomic, weak) IBOutlet GuidedTextField *passwordTextField;

@end

@implementation LogInViewController

BOOL didShowFeedback;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.facebookButton setTitle:NSLocalizedString(@"REGISTER_BUTTON_LOGIN_WITH_FACEBOOK", nil) forState:UIControlStateNormal];
    self.emailTextField.guideText = NSLocalizedString(@"REGISTER_FIELD_EMAIL", nil);
    self.emailTextField.guidedDelegate = self;
    self.passwordTextField.guideText = NSLocalizedString(@"REGISTER_FIELD_PASSWORD", nil);
    self.passwordTextField.guidedDelegate = self;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"REGISTER_BUTTON_LOGIN", nil) style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPushed)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
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
    [AccountUtil registerWithPassword:self.passwordTextField.text email:self.emailTextField.text firstName:nil lastName:nil action:AuthenticationActionLogin success:^(enum AuthenticationResponseType response) {

        if (response == AuthenticationResponsePaired || response == AuthenticationResponseCreated) {
            if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
                RegisterNavigationController *registerNavigationController = (RegisterNavigationController*) self.navigationController;
                if (registerNavigationController.registerDelegate) {
                    [registerNavigationController.registerDelegate userAuthenticated];
                }
            }
        }
        else if (response == AuthenticationResponseInvalidCredentials) {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_INVALID_CREDENTIALS_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_INVALID_CREDENTIALS_TITLE", nil)];
        }
        else if (response == AuthenticationResponseMalformedEmail) {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_MALFORMED_EMAIL_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_MALFORMED_EMAIL_TITLE", nil)];
        }
        else {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_TITLE", nil)];
        }
    } failure:^(enum AuthenticationResponseType response) {
        [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_TITLE", nil)];
    }];
}

- (IBAction)facebookButtonPushed:(id)sender {
    
    [self.activityIndicator startAnimating];
    [self.facebookButton setTitle:@"" forState:UIControlStateNormal];

    didShowFeedback = NO;
    vaavudAppDelegate *appDelegate = (vaavudAppDelegate*) [UIApplication sharedApplication].delegate;
    appDelegate.facebookAuthenticationDelegate = self;
    [appDelegate openFacebookSession:AuthenticationActionLogin];
}

- (void) facebookAuthenticationSuccess:(enum AuthenticationResponseType)response {

    [self.activityIndicator stopAnimating];
    [self.facebookButton setTitle:NSLocalizedString(@"REGISTER_BUTTON_LOGIN_WITH_FACEBOOK", nil) forState:UIControlStateNormal];
    
    if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
        RegisterNavigationController *registerNavigationController = (RegisterNavigationController*) self.navigationController;
        if (registerNavigationController.registerDelegate) {
            [registerNavigationController.registerDelegate userAuthenticated];
        }
    }
}

- (void) facebookAuthenticationFailure:(enum AuthenticationResponseType)response message:(NSString*)message displayFeedback:(BOOL)displayFeedback {

    NSLog(@"[LogInViewController] error registering user");
    
    [self.activityIndicator stopAnimating];
    [self.facebookButton setTitle:NSLocalizedString(@"REGISTER_BUTTON_LOGIN_WITH_FACEBOOK", nil) forState:UIControlStateNormal];
    
    if (displayFeedback && !didShowFeedback) {
        didShowFeedback = YES;
        if (!message) {
            message = NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_MESSAGE", nil);
        }
        [self showMessage:message withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_TITLE", nil)];
    }
}

- (void)changedEmptiness:(UITextField*)textField isEmpty:(BOOL)isEmpty {
    UITextField *otherTextField = (textField == self.emailTextField) ? self.passwordTextField : self.emailTextField;
    if (!isEmpty && otherTextField.text.length > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.emailTextField.text.length > 0 && self.passwordTextField.text.length > 0) {
        [self doneButtonPushed];
    }
    else if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (textField == self.passwordTextField) {
        [self.emailTextField becomeFirstResponder];
    }
    return YES;
}

- (void)showMessage:(NSString *)text withTitle:(NSString *)title {
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                      otherButtonTitles:nil] show];
}

@end
