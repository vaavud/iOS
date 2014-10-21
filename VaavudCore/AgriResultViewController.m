//
//  AgriResultViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 02/10/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AgriResultViewController.h"

@interface AgriResultViewController ()

@property (nonatomic, weak) IBOutlet UILabel *windSpeedHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel *averageLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *windSpeedUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *directionImageView;
@property (weak, nonatomic) IBOutlet UILabel *reducingEquipmentHeadingLabel;
@property (weak, nonatomic) IBOutlet UISwitch *reducingEquipmentSwitch;
@property (weak, nonatomic) IBOutlet UILabel *doseHeadingLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *doseSegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *boomHeightHeadingLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *boomHeightSegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *sprayQualityHeadingLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sprayQualitySegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *protectiveDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *generalDistanceHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *generalDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *generalDistanceUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *specialDistanceHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *specialDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *specialDistanceUnitLabel;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@end

@implementation AgriResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)saveButtonPushed:(id)sender {
}

@end
