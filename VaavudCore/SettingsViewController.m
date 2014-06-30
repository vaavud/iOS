//
//  SettingsViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 22/05/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "SettingsViewController.h"
#import "AccountManager.h"
#import "Property+Util.h"
#import "UnitUtil.h"
#import "RegisterNavigationController.h"
#import "vaavudAppDelegate.h"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) UIWebView *webView;

@end

@implementation SettingsViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    }

    self.navigationItem.title = NSLocalizedString(@"SETTINGS_TITLE", nil);
    self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"NAVIGATION_BACK", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectZero];
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshLogoutButton];
    NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
    if (selectedRow) {
        [self.tableView deselectRowAtIndexPath:selectedRow animated:NO];
    }
    [self.tableView reloadData];
}

- (void) refreshLogoutButton {
    if ([[AccountManager sharedInstance] isLoggedIn]) {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"REGISTER_BUTTON_LOGOUT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(logoutButtonPushed)];
        self.navigationItem.rightBarButtonItem = item;
    }
    else {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"REGISTER_BUTTON_LOGIN", nil) style:UIBarButtonItemStylePlain target:self action:@selector(gotoRegisterViewController)];
        self.navigationItem.rightBarButtonItem = item;
    }
}

- (void) logoutButtonPushed {
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"REGISTER_BUTTON_LOGOUT", nil)
                                message:NSLocalizedString(@"DIALOG_CONFIRM", nil)
                               delegate:self
                      cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                      otherButtonTitles:NSLocalizedString(@"BUTTON_OK", nil), nil] show];
    
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self gotoRegisterViewController];
    }
}

- (void) gotoRegisterViewController {

    if ([[AccountManager sharedInstance] isLoggedIn]) {
        [[AccountManager sharedInstance] logout];
    }
    
    if ([[AccountManager sharedInstance] getAuthenticationState] == AuthenticationStateNeverLoggedIn) {
        
        // note: for this to work, the UINavigationController we're in (MeasureNavigationController) must be a subclass of RegisterNavigationController
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Register" bundle:nil];
        UIViewController *nextViewController = [storyboard instantiateViewControllerWithIdentifier:@"RegisterViewController"];
        if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
            ((RegisterNavigationController*) self.navigationController).registerDelegate = (vaavudAppDelegate*) [UIApplication sharedApplication].delegate;
        }
        [self.navigationController pushViewController:nextViewController animated:YES];
    }
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Register" bundle:nil];
        UIViewController *nextViewController = [storyboard instantiateInitialViewController];
        if ([nextViewController isKindOfClass:[RegisterNavigationController class]]) {
            ((RegisterNavigationController*) nextViewController).registerDelegate = (vaavudAppDelegate*) [UIApplication sharedApplication].delegate;
        }
        [UIApplication sharedApplication].delegate.window.rootViewController = nextViewController;
        //nextViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        //[self presentViewController:nextViewController animated:YES completion:nil];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:indexPath];
    
    cell.textLabel.textColor = [UIColor darkGrayColor];
    
    switch (indexPath.item) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"HEADING_UNIT", nil);
            cell.detailTextLabel.text = [UnitUtil displayNameForWindSpeedUnit:[[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue]];
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"SETTINGS_SHOP_LINK", nil);
            cell.detailTextLabel.text = nil;
            break;
        case 2:
            cell.textLabel.text = NSLocalizedString(@"ABOUT_TITLE", nil);
            cell.detailTextLabel.text = nil;
            break;
    }
    
    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {

    switch (indexPath.item) {
        case 0: {
            [self performSegueWithIdentifier:@"unitSegue" sender:self];
            break;
        }
        case 1: {
            NSString *country = [Property getAsString:KEY_COUNTRY];
            NSString *language = [Property getAsString:KEY_LANGUAGE];
            NSString *url = [NSString stringWithFormat:@"http://vaavud.com/mobile-shop-redirect/?country=%@&language=%@", country, language];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            break;
        }
        case 2: {
            [self performSegueWithIdentifier:@"aboutSegue" sender:self];
            break;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

@end