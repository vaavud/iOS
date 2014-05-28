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

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) UIWebView *webView;

@end

@implementation SettingsViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
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
}

- (void) refreshLogoutButton {
    if (LOGOUT_ENABLED && [[AccountManager sharedInstance] isLoggedIn]) {
        if (!self.navigationItem.rightBarButtonItem) {
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"REGISTER_BUTTON_LOGOUT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(logoutButtonPushed)];
            self.navigationItem.rightBarButtonItem = item;
        }
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void) logoutButtonPushed {
    [[AccountManager sharedInstance] logout];
    [self refreshLogoutButton];
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
