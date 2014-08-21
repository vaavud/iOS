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
        
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {

#ifdef CORE
        UIImage *selectedTabImage = [[UIImage imageNamed:@"measure_selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.tabBarItem.selectedImage = selectedTabImage;
#endif

    }
    else {
        self.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationBar.tintColor = [UIColor blackColor];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
