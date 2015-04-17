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
#import "AccountManager.h"
#import "Mixpanel.h"
#import <FacebookSDK/FacebookSDK.h>

@interface LogInViewController ()<UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *basicInputView;
@property (nonatomic, weak) IBOutlet UIButton *facebookButton;
@property (nonatomic, weak) IBOutlet UILabel *orLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UITextField *emailTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic) UIAlertView *alertView;

@end

@implementation LogInViewController

BOOL didShowFeedback;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    self.basicInputView.layer.cornerRadius = FORM_CORNER_RADIUS;
    self.basicInputView.layer.masksToBounds = YES;
    
    self.facebookButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.facebookButton.layer.masksToBounds = YES;

    [self refreshLoginButton];

    if (!self.navigationController || self.navigationController.viewControllers.count <= 1) {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) style:UIBarButtonItemStylePlain target:self action:@selector(crossButtonPushed)];
        self.navigationItem.leftBarButtonItem = item;
    }
}

- (void)crossButtonPushed {
    if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
        RegisterNavigationController *registerNavigationController = (RegisterNavigationController *)self.navigationController;
        if (registerNavigationController.registerDelegate) {
            [registerNavigationController.registerDelegate cancelled:self];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Signup/Login Screen" properties:@{@"Screen": @"Login"}];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.alertView.delegate = nil;
    [AccountManager sharedInstance].delegate = nil;
}


- (IBAction)textFieldDidChange:(UITextField *)sender {
    [self refreshLoginButton];
}

- (void)refreshLoginButton {
    NSLog(@"refresh: %d:%d", self.emailTextField.text.length, self.passwordTextField.text.length);

    self.navigationItem.rightBarButtonItem.enabled = self.emailTextField.text.length > 0 && self.passwordTextField.text.length > 0;
}

- (IBAction)doneButtonPushed:(UIBarButtonItem *)sender {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [activityIndicator startAnimating];

    [[AccountManager sharedInstance] registerWithPassword:self.passwordTextField.text email:self.emailTextField.text firstName:nil lastName:nil action:AuthenticationActionLogin success:^(enum AuthenticationResponseType response) {

        [self.passwordTextField resignFirstResponder];
        [self.emailTextField resignFirstResponder];
        self.passwordTextField.delegate = nil;
        self.emailTextField.delegate = nil;
        
        if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
            RegisterNavigationController *registerNavigationController = (RegisterNavigationController *)self.navigationController;
            if (registerNavigationController.registerDelegate) {
                [registerNavigationController.registerDelegate userAuthenticated:(response == AuthenticationResponseCreated) viewController:self];
            }
        }
        
        if (self.completion) {
            self.completion();
        }
    } failure:^(enum AuthenticationResponseType response) {
        if ([Property isMixpanelEnabled]) {
            [[Mixpanel sharedInstance] track:@"Register Error" properties:@{@"Response": [NSNumber numberWithInt:response], @"Screen": @"Login", @"Method": @"Password"}];
        }
        
        [self refreshLoginButton];

        if (response == AuthenticationResponseInvalidCredentials) {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_INVALID_CREDENTIALS_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_INVALID_CREDENTIALS_TITLE", nil)];
        }
        else if (response == AuthenticationResponseMalformedEmail) {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_MALFORMED_EMAIL_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_MALFORMED_EMAIL_TITLE", nil)];
        }
        else if (response == AuthenticationResponseLoginWithFacebook) {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_ACCOUNT_EXISTS_LOGIN_WITH_FACEBOOK", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ACCOUNT_EXISTS_TITLE", nil)];
        }
        else if (response == AuthenticationResponseNoReachability) {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_NO_REACHABILITY_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_NO_REACHABILITY_TITLE", nil)];
        }
        else {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_TITLE", nil)];
        }
    }];
}

- (IBAction)facebookButtonPushed:(id)sender {
    [self facebookButtonPushed:sender password:nil];
}

- (void)facebookButtonPushed:(id)sender password:(NSString *)password {
    [self.activityIndicator startAnimating];
    self.facebookButton.titleLabel.hidden = YES;

    didShowFeedback = NO;
    AccountManager *accountManager = [AccountManager sharedInstance];
    accountManager.delegate = self;
    [accountManager registerWithFacebook:password action:AuthenticationActionLogin];
}

- (void)facebookAuthenticationSuccess:(enum AuthenticationResponseType)response {
    [self.activityIndicator stopAnimating];
    self.facebookButton.titleLabel.hidden = NO;

    if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
        RegisterNavigationController *registerNavigationController = (RegisterNavigationController *)self.navigationController;
        if (registerNavigationController.registerDelegate) {
            [registerNavigationController.registerDelegate userAuthenticated:(response == AuthenticationResponseCreated) viewController:self];
        }
    }
    if (self.completion) {
        self.completion();
    }
}

- (void)facebookAuthenticationFailure:(enum AuthenticationResponseType)response
                              message:(NSString *)message
                      displayFeedback:(BOOL)displayFeedback {

    if (LOG_OTHER) NSLog(@"[LogInViewController] error registering user, response=%d, message=%@, displayFeedback=%@", response, message, (displayFeedback ? @"YES" : @"NO"));
    
    [self.activityIndicator stopAnimating];
    self.facebookButton.titleLabel.hidden = NO;

    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Register Error" properties:@{@"Response": [NSNumber numberWithInt:response], @"Screen": @"Login", @"Method": @"Facebook"}];
    }
    
    if (displayFeedback && !didShowFeedback) {
        didShowFeedback = YES;
        if (!message || message.length == 0) {
            if (response == AuthenticationResponseEmailUsedProvidePassword) {
                [self promptForPassword];
                return;
            }
            else if (response == AuthenticationResponseNoReachability) {
                [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_NO_REACHABILITY_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_NO_REACHABILITY_TITLE", nil)];
                return;
            }
            else if (response == AuthenticationResponseFacebookMissingPermission) {
                [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_MISSING_FACEBOOK_PERMISSIONS_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_MISSING_FACEBOOK_PERMISSIONS_TITLE", nil)];
                return;
            }
            else {
                message = NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_MESSAGE", nil);
            }
        }
        [self showMessage:message withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_TITLE", nil)];
    }
}

//- (void)changedEmptiness:(UITextField *)textField isEmpty:(BOOL)isEmpty {
//    UITextField *otherTextField = (textField == self.emailTextField) ? self.passwordTextField : self.emailTextField;
//    if (!otherTextField) {
//        return;
//    }
//    if (!isEmpty && otherTextField.text.length > 0) {
//        self.navigationItem.rightBarButtonItem.enabled = YES;
//    }
//    else {
//        self.navigationItem.rightBarButtonItem.enabled = NO;
//    }
//}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.emailTextField.text.length > 0 && self.passwordTextField.text.length > 0) {
        [self refreshLoginButton];
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
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:text
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {}]];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:title
                                    message:text
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                          otherButtonTitles:nil] show];
    }
}

- (void)promptForPassword {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ACCOUNT_EXISTS_TITLE", nil)
                                                                                 message:NSLocalizedString(@"REGISTER_FEEDBACK_ACCOUNT_EXISTS_PROVIDE_PASSWORD", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {}]];

        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              UITextField *passwordTextField = alertController.textFields[0];
                                                              if (passwordTextField && passwordTextField.text.length > 0) {
                                                                  [self facebookButtonPushed:nil password:passwordTextField.text];
                                                              }
                                                          }]];
        
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.secureTextEntry = YES;
        }];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else {
        self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ACCOUNT_EXISTS_TITLE", nil)
                                                    message:NSLocalizedString(@"REGISTER_FEEDBACK_ACCOUNT_EXISTS_PROVIDE_PASSWORD", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                          otherButtonTitles:NSLocalizedString(@"BUTTON_OK", nil), nil];
        
        self.alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
        [self.alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        UITextField *passwordTextField = [alertView textFieldAtIndex:0];
        if (passwordTextField && passwordTextField.text.length > 0) {
            [self facebookButtonPushed:nil password:passwordTextField.text];
        }
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    UITextField *passwordTextField = [alertView textFieldAtIndex:0];
    if (passwordTextField && passwordTextField.text.length > 0) {
        return YES;
    }
    return NO;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.alertView = nil;
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

//- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
//    [self refreshLoginButton];
//    return YES;
//}

@end
