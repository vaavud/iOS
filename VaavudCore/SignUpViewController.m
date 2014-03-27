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
#import "TermsPrivacyViewController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "Mixpanel.h"
#import <FacebookSDK/FacebookSDK.h>

#define TAB_BAR_HEIGHT 49

@interface SignUpViewController ()

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UIView *basicInputView;
@property (nonatomic, weak) IBOutlet UIButton *facebookButton;
@property (nonatomic, weak) IBOutlet UILabel *orLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet GuidedTextField *firstNameTextField;
@property (nonatomic, weak) IBOutlet GuidedTextField *lastNameTextField;
@property (nonatomic, weak) IBOutlet GuidedTextField *emailTextField;
@property (nonatomic, weak) IBOutlet GuidedTextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UIView *termsPrivacyView;
@property (nonatomic, weak) IBOutlet UIButton *termsButton;
@property (nonatomic, weak) IBOutlet UIButton *privacyButton;
@property (nonatomic, weak) IBOutlet UILabel *andLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *termsPrivacyViewWidthConstraint;
@property (nonatomic) UIAlertView *alertView;

@end

@implementation SignUpViewController

BOOL didShowFeedback;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.facebookButton setTitle:NSLocalizedString(@"REGISTER_BUTTON_SIGNUP_WITH_FACEBOOK", nil) forState:UIControlStateNormal];
    self.orLabel.text = NSLocalizedString(@"REGISTER_OR", nil);
    self.firstNameTextField.guideText = NSLocalizedString(@"REGISTER_FIELD_FIRST_NAME", nil);
    self.firstNameTextField.guidedDelegate = self;
    self.lastNameTextField.guideText = NSLocalizedString(@"REGISTER_FIELD_LAST_NAME", nil);
    self.lastNameTextField.guidedDelegate = self;
    self.emailTextField.guideText = NSLocalizedString(@"REGISTER_FIELD_EMAIL", nil);
    self.emailTextField.guidedDelegate = self;
    self.passwordTextField.guideText = NSLocalizedString(@"REGISTER_FIELD_PASSWORD", nil);
    self.passwordTextField.guidedDelegate = self;
    [self.termsButton setTitle:NSLocalizedString(@"LINK_TERMS_OF_SERVICE", nil) forState:UIControlStateNormal];
    [self.privacyButton setTitle:NSLocalizedString(@"LINK_PRIVACY_POLICY", nil) forState:UIControlStateNormal];
    self.andLabel.text = NSLocalizedString(@"REGISTER_TERMS_AND", nil);
    
    self.navigationItem.title = NSLocalizedString(@"REGISTER_TITLE_SIGNUP", nil);
    [self createRegisterButton];

    self.basicInputView.layer.cornerRadius = FORM_CORNER_RADIUS;
    self.basicInputView.layer.masksToBounds = YES;

    self.facebookButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.facebookButton.layer.masksToBounds = YES;
    
    CGSize termsTextSize = [self.termsButton sizeThatFits:CGSizeMake(FLT_MAX, 20.0)];
    CGSize andTextSize = [self.andLabel sizeThatFits:CGSizeMake(FLT_MAX, 20.0)];
    CGSize privacyTextSize = [self.privacyButton sizeThatFits:CGSizeMake(FLT_MAX, 20.0)];
    self.termsPrivacyViewWidthConstraint.constant = termsTextSize.width + 4.0 + andTextSize.width + 4.0 + privacyTextSize.width;    
}

- (void) viewWillAppear:(BOOL)animated {
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
        [tracker set:kGAIScreenName value:@"Signup Screen"];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    }

    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Signup Screen"];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];

    self.alertView.delegate = nil;
    [AccountManager sharedInstance].delegate = nil;
}

- (void) createRegisterButton {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"REGISTER_BUTTON_CREATE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPushed)];
}

- (void) doneButtonPushed {

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

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [activityIndicator startAnimating];

    [[AccountManager sharedInstance] registerWithPassword:self.passwordTextField.text email:self.emailTextField.text firstName:self.firstNameTextField.text lastName:self.lastNameTextField.text action:AuthenticationActionSignup success:^(enum AuthenticationResponseType response) {
        
        if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
            RegisterNavigationController *registerNavigationController = (RegisterNavigationController*) self.navigationController;
            if (registerNavigationController.registerDelegate) {
                [registerNavigationController.registerDelegate userAuthenticated:(response == AuthenticationResponseCreated)];
            }
        }
    } failure:^(enum AuthenticationResponseType response) {
        
        if ([Property isMixpanelEnabled]) {
            [[Mixpanel sharedInstance] track:@"Register Error" properties:@{@"Response": [NSNumber numberWithInt:response]}];
        }
        
        [self createRegisterButton];

        if (response == AuthenticationResponseInvalidCredentials) {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_ACCOUNT_EXISTS_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ACCOUNT_EXISTS_TITLE", nil)];
            [self.passwordTextField becomeFirstResponder];
        }
        else if (response == AuthenticationResponseMalformedEmail) {
            [self showMessage:NSLocalizedString(@"REGISTER_FEEDBACK_MALFORMED_EMAIL_MESSAGE", nil) withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_MALFORMED_EMAIL_TITLE", nil)];
            [self.emailTextField becomeFirstResponder];
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

- (IBAction) facebookButtonPushed:(id)sender {
    [self facebookButtonPushed:sender password:nil];
}

- (void) facebookButtonPushed:(id)sender password:(NSString*)password {
    
    [self.activityIndicator startAnimating];
    [self.facebookButton setTitle:@"" forState:UIControlStateNormal];

    didShowFeedback = NO;
    AccountManager *accountManager = [AccountManager sharedInstance];
    accountManager.delegate = self;
    [accountManager registerWithFacebook:password action:AuthenticationActionSignup];
}

- (void) facebookAuthenticationSuccess:(enum AuthenticationResponseType)response {

    [self.activityIndicator stopAnimating];
    [self.facebookButton setTitle:NSLocalizedString(@"REGISTER_BUTTON_SIGNUP_WITH_FACEBOOK", nil) forState:UIControlStateNormal];
    
    if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
        RegisterNavigationController *registerNavigationController = (RegisterNavigationController*) self.navigationController;
        if (registerNavigationController.registerDelegate) {
            [registerNavigationController.registerDelegate userAuthenticated:(response == AuthenticationResponseCreated)];
        }
    }
}

- (void) facebookAuthenticationFailure:(enum AuthenticationResponseType)response message:(NSString*)message displayFeedback:(BOOL)displayFeedback {

    NSLog(@"[SignUpViewController] error registering user, response=%u, message=%@, displayFeedback=%@", response, message, (displayFeedback ? @"YES" : @"NO"));
    
    [self.activityIndicator stopAnimating];
    [self.facebookButton setTitle:NSLocalizedString(@"REGISTER_BUTTON_SIGNUP_WITH_FACEBOOK", nil) forState:UIControlStateNormal];
    
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Register Error" properties:@{@"Response": [NSNumber numberWithInt:response]}];
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
            else {
                message = NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_MESSAGE", nil);
            }
        }
        [self showMessage:message withTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ERROR_TITLE", nil)];
    }
}

- (void) showMessage:(NSString *)text withTitle:(NSString *)title {
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                      otherButtonTitles:nil] show];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    
    if (self.firstNameTextField.text.length > 0 && self.emailTextField.text.length > 0 && self.passwordTextField.text.length > 0) {
        [self doneButtonPushed];
    }
    else if (textField == self.firstNameTextField) {
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


- (void) promptForPassword {
    self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"REGISTER_FEEDBACK_ACCOUNT_EXISTS_TITLE", nil)
                                                message:NSLocalizedString(@"REGISTER_FEEDBACK_ACCOUNT_EXISTS_PROVIDE_PASSWORD", nil)
                                               delegate:self
                                      cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                      otherButtonTitles:NSLocalizedString(@"BUTTON_OK", nil), nil];
    
    self.alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [self.alertView show];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        UITextField *passwordTextField = [alertView textFieldAtIndex:0];
        if (passwordTextField && passwordTextField.text.length > 0) {
            [self facebookButtonPushed:nil password:passwordTextField.text];
        }
    }
}

- (BOOL) alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    UITextField *passwordTextField = [alertView textFieldAtIndex:0];
    if (passwordTextField && passwordTextField.text.length > 0) {
        return YES;
    }
    return NO;
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.alertView = nil;
}

- (IBAction) termsButtonPushed:(id)sender {
    UINavigationController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"TermsPrivacyNavigationController"];
    TermsPrivacyViewController *termsPrivacyController = (TermsPrivacyViewController*) controller.topViewController;
    termsPrivacyController.screenName = @"Signup Terms Screen";
    termsPrivacyController.termsPrivacyTitle = NSLocalizedString(@"LINK_TERMS_OF_SERVICE", nil);
    termsPrivacyController.termsPrivacyURL = @"http://vaavud.com/legal/terms?source=app";
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction) privacyButtonPushed:(id)sender {
    UINavigationController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"TermsPrivacyNavigationController"];
    TermsPrivacyViewController *termsPrivacyController = (TermsPrivacyViewController*) controller.topViewController;
    termsPrivacyController.screenName = @"Signup Privacy Screen";
    termsPrivacyController.termsPrivacyTitle = NSLocalizedString(@"LINK_PRIVACY_POLICY", nil);
    termsPrivacyController.termsPrivacyURL = @"http://vaavud.com/legal/privacy?source=app";
    [self presentViewController:controller animated:YES completion:nil];
}

-(void) keyboardWillShow:(NSNotification*)aNotification {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        NSDictionary* info = [aNotification userInfo];
        CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        
        self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0.0, kbSize.height - TAB_BAR_HEIGHT, 0.0);
        self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(self.scrollView.scrollIndicatorInsets.top, 0.0, kbSize.height - TAB_BAR_HEIGHT, 0.0);
        
        [self.scrollView scrollRectToVisible:self.termsPrivacyView.frame animated:YES];
    }
}

-(void) keyboardWillHide:(NSNotification*)aNotification {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        CGFloat bottomInset = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") ? self.bottomLayoutGuide.length : 0.0;
        
        self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0.0, bottomInset, 0.0);
        self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(self.scrollView.scrollIndicatorInsets.top, 0.0, bottomInset, 0.0);
    }
}

@end
