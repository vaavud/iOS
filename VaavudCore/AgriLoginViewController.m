//
//  AgriLoginViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 21/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AgriLoginViewController.h"
#import "Mixpanel.h"
#import "Property+Util.h"
#import "ServerUploadManager.h"

@interface AgriLoginViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *basicInputView;
@property (weak, nonatomic) IBOutlet GuidedTextField *emailTextField;
@property (weak, nonatomic) IBOutlet GuidedTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic) CGFloat contentOffsetAfterShowingKeyboard;

@end

@implementation AgriLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.loginButton setTitle:NSLocalizedString(@"REGISTER_BUTTON_LOGIN", nil) forState:UIControlStateNormal];
    [self.registerButton setTitle:NSLocalizedString(@"AGRI_REGISTER_BUTTON", nil) forState:UIControlStateNormal];
    
    self.emailTextField.guideText = NSLocalizedString(@"REGISTER_FIELD_EMAIL", nil);
    self.emailTextField.delegate = self;
    self.passwordTextField.guideText = NSLocalizedString(@"REGISTER_FIELD_PASSWORD", nil);
    self.passwordTextField.delegate = self;
    
    self.emailTextField.tintColor = [UIColor whiteColor];
    self.passwordTextField.tintColor = [UIColor whiteColor];
    
    self.basicInputView.layer.cornerRadius = FORM_CORNER_RADIUS;
    self.basicInputView.layer.masksToBounds = YES;
    
    self.loginButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.loginButton.layer.masksToBounds = YES;
    self.registerButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.registerButton.layer.masksToBounds = YES;
    
    // Listen to keyboard...
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Agri Login Screen"];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (IBAction)loginButtonClicked:(id)sender {

    if (self.emailTextField.text == nil || self.emailTextField.text.length == 0) {
        [self.emailTextField becomeFirstResponder];
        return;
    }
    
    if (self.passwordTextField.text == nil || self.passwordTextField.text.length == 0) {
        [self.passwordTextField becomeFirstResponder];
        return;
    }
  
    //[self.emailTextField resignFirstResponder];
    //[self.passwordTextField resignFirstResponder];
    [self.activityIndicator startAnimating];
    
    [[AccountManager sharedInstance] registerWithPassword:self.passwordTextField.text email:self.emailTextField.text firstName:nil lastName:nil action:AuthenticationActionLogin success:^(enum AuthenticationResponseType response) {
        
        [self.activityIndicator stopAnimating];

        [self.passwordTextField resignFirstResponder];
        [self.emailTextField resignFirstResponder];
        self.passwordTextField.delegate = nil;
        self.emailTextField.delegate = nil;
        
        if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
            RegisterNavigationController *registerNavigationController = (RegisterNavigationController*) self.navigationController;
            if (registerNavigationController.registerDelegate) {
                [registerNavigationController.registerDelegate userAuthenticated:(response == AuthenticationResponseCreated) viewController:self];
            }
        }
        else {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Agriculture" bundle:nil];
            UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"AgriTabBarController"];
            [UIApplication sharedApplication].delegate.window.rootViewController = viewController;
        }
        
        [[ServerUploadManager sharedInstance] syncHistory:1 ignoreGracePeriod:YES success:nil failure:nil];

    } failure:^(enum AuthenticationResponseType response) {

        [self.activityIndicator stopAnimating];

        if ([Property isMixpanelEnabled]) {
            [[Mixpanel sharedInstance] track:@"Register Error" properties:@{@"Response": [NSNumber numberWithInt:response], @"Screen": @"Agri Login", @"Method": @"Password"}];
        }
        
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

- (IBAction)registerButtonClicked:(id)sender {

}

- (void) showMessage:(NSString *)text withTitle:(NSString *)title {
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                      otherButtonTitles:nil] show];
}

- (void) changedEmptiness:(UITextField*)textField isEmpty:(BOOL)isEmpty {
    
    UITextField *otherTextField = (textField == self.emailTextField) ? self.passwordTextField : self.emailTextField;
    if (!otherTextField) {
        return;
    }
    if (!isEmpty && otherTextField.text.length > 0) {

    }
    else {

    }
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    
    if (self.emailTextField.text.length > 0 && self.passwordTextField.text.length > 0) {
        [self loginButtonClicked:nil];
    }
    else if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (textField == self.passwordTextField) {
        [self.emailTextField becomeFirstResponder];
    }
    return YES;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    GuidedTextField *guidedTextField = (GuidedTextField*) textField;
    if (!guidedTextField) {
        return YES;
    }
    
    NSRange textFieldRange = NSMakeRange(0, [textField.text length]);
    if ((NSEqualRanges(range, textFieldRange) && [string length] == 0) || (textField.secureTextEntry && guidedTextField.isFirstEdit && range.location > 0 && range.length == 1 && string.length == 0)) {
        if (guidedTextField.label.hidden) {
            guidedTextField.label.hidden = NO;
            [self changedEmptiness:textField isEmpty:YES];
        }
    }
    else {
        if (!guidedTextField.label.hidden) {
            guidedTextField.label.hidden = YES;
            [self changedEmptiness:textField isEmpty:NO];
        }
    }
    
    guidedTextField.isFirstEdit = NO;
    
    return YES;
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    
    GuidedTextField *guidedTextField = (GuidedTextField*) textField;
    guidedTextField.isFirstEdit = YES;
    return YES;
}

- (void) keyboardWillShow:(NSNotification*)aNotification {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        
        NSDictionary* info = [aNotification userInfo];
        CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        UIViewAnimationCurve animationCurve = [info[UIKeyboardAnimationCurveUserInfoKey] integerValue];
        CGFloat bottomInset = kbSize.height - self.bottomLayoutGuide.length;
        
        self.contentOffsetAfterShowingKeyboard = 0.0;
        
        [UIView animateWithDuration:[info[UIKeyboardAnimationDurationUserInfoKey] doubleValue] delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews | animationCurve << 16) animations:^{
            
            self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0.0, bottomInset, 0.0);
            self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(self.scrollView.scrollIndicatorInsets.top, 0.0, bottomInset, 0.0);
            
            [self.scrollView scrollRectToVisible:CGRectMake(0.0, self.loginButton.frame.origin.y + self.loginButton.frame.size.height + 10.0, self.loginButton.frame.size.width, 1.0) animated:NO];
            
        } completion:^(BOOL finished) {
            self.contentOffsetAfterShowingKeyboard = self.scrollView.contentOffset.y;
        }];
    }
}

- (void) keyboardWillHide:(NSNotification*)aNotification {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        NSDictionary* info = [aNotification userInfo];
        UIViewAnimationCurve animationCurve = [info[UIKeyboardAnimationCurveUserInfoKey] integerValue];
        CGFloat bottomInset = self.bottomLayoutGuide.length;
        
        [UIView animateWithDuration:[info[UIKeyboardAnimationDurationUserInfoKey] doubleValue] delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews | animationCurve << 16) animations:^{
            
            self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0.0, bottomInset, 0.0);
            self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(self.scrollView.scrollIndicatorInsets.top, 0.0, bottomInset, 0.0);
            
        } completion:^(BOOL finished) {
            
        }];
    }
}

@end
