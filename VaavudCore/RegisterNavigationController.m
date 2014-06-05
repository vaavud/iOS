//
//  RegisterNavigationViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "RegisterNavigationController.h"

@implementation RegisterNavigationController


- (void) viewDidLoad {
    [super viewDidLoad];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        self.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationBar.tintColor = [UIColor blackColor];
    }
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
