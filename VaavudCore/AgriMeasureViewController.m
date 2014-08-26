//
//  AgriMeasureViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 25/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AgriMeasureViewController.h"
#import "UIColor+VaavudColors.h"
#import "Property+Util.h"
#import "UnitUtil.h"

@interface AgriMeasureViewController ()

@property (nonatomic, weak) IBOutlet UILabel *windSpeedHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel *averageLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *windSpeedUnitLabel;

@property (nonatomic, weak) IBOutlet UILabel *informationTextLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *statusBar;

@property (nonatomic, weak) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (nonatomic, strong) IBOutlet vaavudGraphHostingView *graphHostView;

@end

@implementation AgriMeasureViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    self.shareToFacebook = NO;
    
    UIColor *vaavudColor = [UIColor vaavudColor];

    self.windSpeedHeadingLabel.text = [NSLocalizedString(@"HEADING_WIND_SPEED", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.temperatureUnitLabel.text = NSLocalizedString(@"UNIT_CELCIUS", nil);
    
    [self.nextButton setTitle:NSLocalizedString(@"BUTTON_NEXT", nil) forState:UIControlStateNormal];
    self.nextButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.nextButton.layer.masksToBounds = YES;
    self.nextButton.backgroundColor = vaavudColor;
    self.nextButton.enabled = NO;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    WindSpeedUnit windSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    self.windSpeedUnitLabel.text = [UnitUtil displayNameForWindSpeedUnit:windSpeedUnit];
}

- (IBAction) startStopButtonPushed:(id)sender {
    [super startStopButtonPushed:sender];
}

- (IBAction) nextButtonPushed:(id)sender {

}

@end
