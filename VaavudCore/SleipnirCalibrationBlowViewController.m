//
//  SleipnirCalibrationBlowViewController.m
//  Vaavud
//
//  Created by Andreas Okholm on 17/12/14.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "SleipnirCalibrationBlowViewController.h"
#import "UIColor+VaavudColors.h"
#import <DACircularProgressView.h>

#define COMPLETION_WAIT_TIME 10.0

@interface SleipnirCalibrationBlowViewController ()
@property (weak, nonatomic) IBOutlet DACircularProgressView *circularProgress;
@property (weak, nonatomic) IBOutlet UILabel *labelProgress;
@property (weak, nonatomic) IBOutlet UILabel *labelDescription;

@property (strong, nonatomic) VEVaavudElectronicSDK *vaavudElectronicSDK;

@end

@implementation SleipnirCalibrationBlowViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        self.view.backgroundColor = [UIColor clearColor];
    }
    
    self.circularProgress.progress = 0.0;
    self.circularProgress.thicknessRatio = 0.0598;
    self.circularProgress.progressTintColor = [UIColor vaavudBlueColor];
    self.circularProgress.trackTintColor = [UIColor vaavudGreyColor];
    
    self.labelProgress.text = @"0%";
    
    self.vaavudElectronicSDK = [VEVaavudElectronicSDK sharedVaavudElectronic];
    [self.vaavudElectronicSDK addListener:self];
    [self.vaavudElectronicSDK startCalibration];
    [self.vaavudElectronicSDK start];
    
    // Do any additional setup after loading the view.
}

- (void)calibrationPercentageComplete:(NSNumber *)percentage {
    self.circularProgress.progress = percentage.floatValue;
    
    self.labelProgress.text = [NSString stringWithFormat:@"%i%%", (int)(percentage.floatValue*100)];
    
    if (percentage.floatValue >= 1) {
        [self.vaavudElectronicSDK stop];
        
        [self performSegueWithIdentifier:@"sleipnirCalibrationComplete" sender:self];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
