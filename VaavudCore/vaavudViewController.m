//
//  vaavudViewController.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "vaavudViewController.h"
#import "VaavudCoreController1.h"

@interface vaavudViewController ()

@end

@implementation vaavudViewController {
    
    VaavudCoreController1 *vaavudCoreController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    vaavudCoreController = [[VaavudCoreController1 alloc] init];
    
    [vaavudCoreController start];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
