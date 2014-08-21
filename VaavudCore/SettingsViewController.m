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
#import "FirstTimeFlowController.h"
#import "Mixpanel.h"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) UIWebView *webView;
@property (nonatomic, strong) UISwitch *facebookSharingSwitch;

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

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshLogoutButton];
    [self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Settings Screen"];
    }
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
        if ([[AccountManager sharedInstance] isLoggedIn]) {
            [[AccountManager sharedInstance] logout];

#ifdef AGRI
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Agriculture" bundle:nil];
            UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"AgriLoginViewController"];
            [UIApplication sharedApplication].delegate.window.rootViewController = viewController;
#elif CORE
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"FirstTimeFlowController"];
            [UIApplication sharedApplication].delegate.window.rootViewController = viewController;
#endif
        }
    }
}

- (void) gotoRegisterViewController {

    if ([[AccountManager sharedInstance] isLoggedIn]) {
        [[AccountManager sharedInstance] logout];
    }
    
    // note: for this to work, the UINavigationController we're in (MeasureNavigationController) must be a subclass of RegisterNavigationController
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Register" bundle:nil];
    UIViewController *nextViewController = [storyboard instantiateViewControllerWithIdentifier:@"RegisterViewController"];
    if ([self.navigationController isKindOfClass:[RegisterNavigationController class]]) {
        ((RegisterNavigationController*) self.navigationController).registerDelegate = (vaavudAppDelegate*) [UIApplication sharedApplication].delegate;
    }
    [self.navigationController pushViewController:nextViewController animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    if (indexPath.item == 0) {
        cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:indexPath];
        cell.textLabel.text = NSLocalizedString(@"HEADING_UNIT", nil);
        cell.detailTextLabel.text = [UnitUtil displayNameForWindSpeedUnit:[[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue]];
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else if (indexPath.item == 1) {
        cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"switchCell"];
        }
        
        if (!self.facebookSharingSwitch) {
            self.facebookSharingSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            self.facebookSharingSwitch.on = [Property getAsBoolean:KEY_ENABLE_SHARE_DIALOG defaultValue:YES];
            [self.facebookSharingSwitch addTarget:self action:@selector(facebookSharingValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
        
        cell.textLabel.text = NSLocalizedString(@"SETTINGS_SOCIAL_SHARING", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"SETTINGS_SOCIAL_SHARING_DETAILS", nil);
        cell.accessoryView = self.facebookSharingSwitch;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor colorWithWhite:248.0/255.0 alpha:1.0];
    }
    else if (indexPath.item == 2) {
        cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:indexPath];
        cell.textLabel.text = NSLocalizedString(@"SETTINGS_SHOP_LINK", nil);
        cell.detailTextLabel.text = nil;
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else if (indexPath.item == 3) {
        cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:indexPath];
        cell.textLabel.text = NSLocalizedString(@"SETTINGS_MEASURING_TIPS", nil);
        cell.detailTextLabel.text = nil;
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else if (indexPath.item == 4) {
        cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:indexPath];
        cell.textLabel.text = NSLocalizedString(@"ABOUT_TITLE", nil);
        cell.detailTextLabel.text = nil;
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    cell.textLabel.textColor = [UIColor darkGrayColor];

    return cell;
}

- (NSIndexPath*) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 1) {
        return nil;
    }
    return indexPath;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.item == 0) {
        [self performSegueWithIdentifier:@"unitSegue" sender:self];
    }
    else if (indexPath.item == 2) {
        
        [[Mixpanel sharedInstance] track:@"Settings Clicked Buy"];

        NSString *country = [Property getAsString:KEY_COUNTRY];
        NSString *language = [Property getAsString:KEY_LANGUAGE];
        NSString *mixpanelId = [Mixpanel sharedInstance].distinctId;
        NSString *url = [NSString stringWithFormat:@"http://vaavud.com/mobile-shop-redirect/?country=%@&language=%@&ref=%@&source=settings", country, language, mixpanelId];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
    else if (indexPath.item == 3) {
        
        [[Mixpanel sharedInstance] track:@"Settings Clicked Measuring Tips"];
        [FirstTimeFlowController gotoInstructionFlowFrom:self returnViaDismiss:YES];
    }
    else if (indexPath.item == 4) {
        [self performSegueWithIdentifier:@"aboutSegue" sender:self];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (IBAction) facebookSharingValueChanged:(UISwitch*)sender {
    [Property setAsBoolean:self.facebookSharingSwitch.on forKey:KEY_ENABLE_SHARE_DIALOG];
    [[Mixpanel sharedInstance] registerSuperProperties:@{@"Enable Share Dialog" : (self.facebookSharingSwitch.on ? @"true" : @"false")}];
}

@end
