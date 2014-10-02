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
#import "MeasurementSession+Util.h"

@interface AgriMeasureViewController ()

@property (nonatomic, weak) IBOutlet UILabel *windSpeedHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel *averageLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *windSpeedUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *directionImageView;

@property (nonatomic, weak) IBOutlet UILabel *informationTextLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *statusBar;

@property (nonatomic, weak) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (weak, nonatomic) IBOutlet UIView *graphContainer;

@property (nonatomic, strong) MeasurementSession *measurementSession;

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

- (NSString*) stopButtonTitle {
    return NSLocalizedString(@"BUTTON_CANCEL", nil);
}

- (IBAction) startStopButtonPushed:(id)sender {
    self.measurementSession = nil;
    [super startStopButtonPushed:sender];
    self.nextButton.enabled = !self.buttonShowsStart;
}

- (void) measurementStopped:(MeasurementSession*)measurementSession {
    self.measurementSession = measurementSession;
}

- (IBAction) nextButtonPushed:(id)sender {
    
    [self stop];
    
    if (self.measurementSession) {
        BOOL hasTemperature = (self.measurementSession.temperature && (self.measurementSession.temperature != (id)[NSNull null]) && ([self.measurementSession.temperature floatValue] > 0.0f));
        BOOL hasDirection = (self.measurementSession.windDirection && (self.measurementSession.windDirection != (id)[NSNull null]));
        
        NSLog(@"[AgriMeasureViewController] Next with temperature=%@ and direction=%@", self.measurementSession.temperature, self.measurementSession.windDirection);
        
        if (hasTemperature && hasDirection) {
            [self performSegueWithIdentifier:@"resultSegue" sender:self];
        }
        else if (!hasTemperature) {
            [self performSegueWithIdentifier:@"temperatureSegue" sender:self];
        }
        else {
            NSLog(@"[AgriMeasureViewController] Missing segue for manual direction");
        }
    }
}

@end
