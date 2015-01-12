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
#import "AccountManager.h"

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

@property (nonatomic) BOOL hasTemperature;
@property (nonatomic) BOOL hasDirection;
@property (nonatomic) BOOL nextAllowed;

@end

@implementation AgriMeasureViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.shareToFacebook = NO;
    self.privacy = [NSNumber numberWithInt:0];
    self.windSpeedHeadingLabel.text = [NSLocalizedString(@"HEADING_WIND_SPEED", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.temperatureUnitLabel.text = NSLocalizedString(@"UNIT_CELCIUS", nil);
    
    [self.nextButton setTitle:NSLocalizedString(@"BUTTON_NEXT", nil) forState:UIControlStateNormal];
    self.nextButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.nextButton.layer.masksToBounds = YES;
    self.nextButton.hidden = YES;
    self.nextButton.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    WindSpeedUnit windSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    self.windSpeedUnitLabel.text = [UnitUtil displayNameForWindSpeedUnit:windSpeedUnit];
    
    if (![Property getAsBoolean:KEY_AGRI_VALID_SUBSCRIPTION]) {
        [[AccountManager sharedInstance] logout];
        
        UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AgriLoginViewController"];
        [UIApplication sharedApplication].delegate.window.rootViewController = viewController;
    }
}

- (NSString *)stopButtonTitle {
    return NSLocalizedString(@"BUTTON_CANCEL", nil);
}

- (void)reset {
    [super reset];
    self.measurementSession = nil;
    self.nextButton.enabled = !self.buttonShowsStart;
    if (!self.buttonShowsStart) {
        self.nextButton.hidden = NO;
    } else {
        self.nextButton.hidden = YES;
    }
}

- (IBAction)startStopButtonPushed:(id)sender {
    self.measurementSession = nil;
    [super startStopButtonPushed:sender];
    self.nextButton.enabled = !self.buttonShowsStart;
    if (!self.buttonShowsStart) {
        self.nextButton.hidden = NO;
    } else {
        self.nextButton.hidden = YES;
    }
    self.nextAllowed = AGRI_DEBUG_ALWAYS_ENABLE_NEXT;
}

- (void)minimumThresholdReached {
    self.nextAllowed = YES;
}

- (void)measurementStopped:(MeasurementSession *)measurementSession {
    self.measurementSession = measurementSession;
    
    // we determine these values here, so that if you later press back after having typed any temperature or direction
    // pressing next again will take you through the same flow again instead of skipping
    self.hasTemperature = (self.measurementSession.temperature && (self.measurementSession.temperature != (id)[NSNull null]) && ([self.measurementSession.temperature floatValue] > 0.0f));
    self.hasDirection = (self.measurementSession.windDirection && (self.measurementSession.windDirection != (id)[NSNull null]));
}

- (IBAction)nextButtonPushed:(id)sender {
    if (!self.nextAllowed) {
        [self showNotification:NSLocalizedString(@"AGRI_MIN_TIME_NOT_REACHED_TITLE", nil) message:NSLocalizedString(@"AGRI_MIN_TIME_NOT_REACHED_MESSAGE", nil) dismissAfter:2.5];
    }
    else {
        // this will only do something if we're measuring, i.e. "measurementStopped" will not be triggered if we're already stopped
        [self stop];
        
        if (self.measurementSession) {
            NSLog(@"[AgriMeasureViewController] Next with temperature=%@ and direction=%@", self.measurementSession.temperature, self.measurementSession.windDirection);
            
            if (self.hasTemperature && self.hasDirection) {
                [self performSegueWithIdentifier:@"resultSegue" sender:self];
            }
            else if (!self.hasTemperature) {
                [self performSegueWithIdentifier:@"manualTemperatureSegue" sender:self];
            }
            else {
                [self performSegueWithIdentifier:@"manualDirectionSegue" sender:self];
            }
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *controller = [segue destinationViewController];
    
    if ([controller conformsToProtocol:@protocol(MeasurementSessionConsumer)]) {
        id<MeasurementSessionConsumer> consumer = (id<MeasurementSessionConsumer>)controller;
        [consumer setMeasurementSession:self.measurementSession];
        [consumer setHasTemperature:self.hasTemperature];
        [consumer setHasDirection:self.hasDirection];
    }
}

@end
