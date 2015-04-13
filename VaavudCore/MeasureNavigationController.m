//
//  MeasureNavigationController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 31/01/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "MeasureNavigationController.h"
#import "Mixpanel.h"
#import "Property+Util.h"

@interface MeasureNavigationController ()

@end

@implementation MeasureNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifdef CORE
        UIImage *selectedTabImage = [[UIImage imageNamed:@"measure_selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.tabBarItem.selectedImage = selectedTabImage;
#endif
}

- (void)tabSelected {
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Measure Tab"];
    }
}

@end
