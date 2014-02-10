//
//  HistoryNavigationController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 24/01/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "HistoryNavigationController.h"

@interface HistoryNavigationController ()

@end

@implementation HistoryNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        self.navigationBar.tintColor = [UIColor blackColor];
        self.navigationBar.barStyle = UIBarStyleBlack;
    }

    self.navigationItem.title = NSLocalizedString(@"HISTORY_TITLE", nil);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
