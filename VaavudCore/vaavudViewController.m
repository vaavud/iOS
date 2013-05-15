//
//  vaavudViewController.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "vaavudViewController.h"
#import "VaavudCoreController.h"

@interface vaavudViewController ()

@end

@implementation vaavudViewController {
    
    VaavudCoreController *vaavudCoreController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    vaavudCoreController = [[VaavudCoreController alloc] init];
    vaavudCoreController.delegate = self;
    [vaavudCoreController start];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) newWindSpeed: (float) speed
{
    self.mainWindSpeedLabel.text = [NSString stringWithFormat: @"%.1f", speed];
}

@end
