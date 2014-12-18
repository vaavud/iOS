//
//  SleipnirCalibrationBlowingViewController.m
//  Vaavud
//
//  Created by Andreas Okholm on 17/12/14.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "SleipnirCalibrationIntroViewController.h"

@interface SleipnirCalibrationIntroViewController ()
@property (weak, nonatomic) IBOutlet UIButton *buttonStart;

@end

@implementation SleipnirCalibrationIntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        self.view.backgroundColor = [UIColor clearColor];
    }
    
    self.buttonStart.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.buttonStart.layer.masksToBounds = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)skipCalibration:(id)sender {
    [self.navigationController.parentViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
