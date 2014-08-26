//
//  AgriSettingsNavigationController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 25/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AgriSettingsNavigationController.h"

@interface AgriSettingsNavigationController ()

@end

@implementation AgriSettingsNavigationController

- (void) awakeFromNib {
    [super awakeFromNib];
    self.tabBarItem.title = NSLocalizedString(@"SETTINGS_TITLE", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
    [self setViewControllers:@[viewController] animated:NO];
}

@end
