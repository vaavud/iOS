//
//  AgriMeasureViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 25/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AgriMeasureViewController.h"
#import "UIColor+VaavudColors.h"

@interface AgriMeasureViewController ()

@property (nonatomic, weak) IBOutlet UILabel *windSpeedHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel *averageLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;

@property (nonatomic, weak) IBOutlet UILabel *informationTextLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *statusBar;

@property (nonatomic, weak) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (nonatomic, strong) IBOutlet vaavudGraphHostingView *graphHostView;

@end

@implementation AgriMeasureViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    UIColor *vaavudColor = [UIColor vaavudColor];

    self.windSpeedHeadingLabel.text = [NSLocalizedString(@"HEADING_WIND_SPEED", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.temperatureHeadingLabel.text = [NSLocalizedString(@"HEADING_TEMPERATURE", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];

    [self.nextButton setTitle:NSLocalizedString(@"BUTTON_NEXT", nil) forState:UIControlStateNormal];
    self.nextButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.nextButton.layer.masksToBounds = YES;
    self.nextButton.backgroundColor = vaavudColor;
    self.nextButton.enabled = NO;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (IBAction) startStopButtonPushed:(id)sender {
    [super startStopButtonPushed:sender];
}

- (IBAction) nextButtonPushed:(id)sender {

}

@end
