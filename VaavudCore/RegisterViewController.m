//
//  LoginRootViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 07/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "RegisterViewController.h"
#import "RegisterNavigationController.h"
#import "AccountManager.h"
#import "Mixpanel.h"
#import "Property+Util.h"

@interface RegisterViewController ()

@property (nonatomic, weak) IBOutlet UILabel *teaserLabel;
@property (nonatomic, weak) IBOutlet UIButton *signUpButton;
@property (nonatomic, weak) IBOutlet UIButton *logInButton;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
        RegisterNavigationController *registerNavigationController = (RegisterNavigationController *)self.navigationController;
        if (registerNavigationController.registerDelegate) {
            
            NSString *title = [registerNavigationController.registerDelegate registerScreenTitle];
            
            if (!title || title.length == 0) {
                self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]];
            }
            else {
                self.navigationItem.title = [registerNavigationController.registerDelegate registerScreenTitle];
            }
            self.teaserLabel.text = [registerNavigationController.registerDelegate registerTeaserText];
        }
    }
    else {
        self.teaserLabel.text = self.teaserLabelText;
    }
    
    self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"BUTTON_CANCEL", nil);
    
    self.signUpButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.signUpButton.layer.masksToBounds = YES;
    [self.signUpButton setTitle:NSLocalizedString(@"REGISTER_TITLE_SIGNUP", nil) forState:UIControlStateNormal];

    self.logInButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.logInButton.layer.masksToBounds = YES;
    [self.logInButton setTitle:NSLocalizedString(@"REGISTER_TITLE_LOGIN", nil) forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Signup/Login Selection Screen"];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController conformsToProtocol:@protocol(AuthenticationDelegate)]) {
        ((id<AuthenticationDelegate>)segue.destinationViewController).completion = self.completion;
    }
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end


