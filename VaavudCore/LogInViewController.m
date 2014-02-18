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
    
    NSString *passwordHash = [PasswordUtil createHash:self.passwordTextField.text salt:self.emailTextField.text];
    NSLog(@"passwordHash=%@", passwordHash);
    
    [[ServerUploadManager sharedInstance] registerUser:@"LOGIN" email:self.emailTextField.text passwordHash:passwordHash facebookId:nil facebookAccessToken:nil firstName:nil lastName:nil gender:nil verified:[NSNumber numberWithInt:0] retry:3 success:^(NSString *status) {
        
        if ([@"PAIRED" isEqualToString:status] || [@"CREATED" isEqualToString:status]) {
            
            [Property setAsString:self.emailTextField.text forKey:KEY_EMAIL];
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
        NSLog(@"[LogInViewController] error registering user");
        [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_TITLE", nil)];
    }];
}

- (IBAction)facebookButtonPushed:(id)sender {
    
    [self.activityIndicator startAnimating];
    [self.facebookButton setTitle:@"" forState:UIControlStateNormal];

    didShowFeedback = NO;
    vaavudAppDelegate *appDelegate = (vaavudAppDelegate*) [UIApplication sharedApplication].delegate;
    appDelegate.facebookAuthenticationDelegate = self;
    [appDelegate openFacebookSession:@"LOGIN"];
}

- (void) facebookAuthenticationSuccess:(NSString*)status {

    [self.activityIndicator stopAnimating];
    [self.facebookButton setTitle:NSLocalizedString(@"REGISTER_BUTTON_LOGIN_WITH_FACEBOOK", nil) forState:UIControlStateNormal];
    
    if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
        RegisterNavigationController *registerNavigationController = (RegisterNavigationController*) self.navigationController;
        if (registerNavigationController.registerDelegate) {
            [registerNavigationController.registerDelegate userAuthenticated];
        }
    }
}

- (void) facebookAuthenticationFailure:(NSString*)status message:(NSString*)message displayFeedback:(BOOL)displayFeedback {

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
