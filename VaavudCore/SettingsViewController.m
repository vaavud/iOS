//
//  SettingsViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 22/05/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

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
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:indexPath];
    
    switch (indexPath.item) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"SETTINGS_SHOP_LINK", nil);
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"ABOUT_TITLE", nil);
            break;
    }
    
    return cell;
}


@end
