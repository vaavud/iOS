//
//  SleipnirCalibrationCompleteViewController.m
//  Vaavud
//
//  Created by Andreas Okholm on 17/12/14.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "SleipnirCalibrationCompleteViewController.h"
#define COMPLETION_WAIT_TIME 5.0


@interface SleipnirCalibrationCompleteViewController ()

@end

@implementation SleipnirCalibrationCompleteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        self.view.backgroundColor = [UIColor clearColor];
    }
    
    [NSTimer scheduledTimerWithTimeInterval:COMPLETION_WAIT_TIME target:self selector:@selector(closeCalibration) userInfo:nil repeats:NO];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) closeCalibration {
    [self performSegueWithIdentifier:@"slipnirCalibrationDismiss" sender:self];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
