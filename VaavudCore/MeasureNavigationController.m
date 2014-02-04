//
//  MeasureNavigationController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 31/01/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "MeasureNavigationController.h"

@interface MeasureNavigationController ()

@end

@implementation MeasureNavigationController

- (void) awakeFromNib {
    [super awakeFromNib];
    self.tabBarItem.title = NSLocalizedString(@"TAB_MEASURE", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.screenName = @"History Screen";
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        UIImage *selectedTabImage = [[UIImage imageNamed:@"measure_selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.tabBarItem.selectedImage = selectedTabImage;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
