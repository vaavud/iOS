//
//  AgriMeasureNavigationController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 25/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AgriMeasureNavigationController.h"

@interface AgriMeasureNavigationController ()

@end

@implementation AgriMeasureNavigationController

- (void) awakeFromNib {
    [super awakeFromNib];
    self.tabBarItem.title = NSLocalizedString(@"TAB_MEASURE", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end
