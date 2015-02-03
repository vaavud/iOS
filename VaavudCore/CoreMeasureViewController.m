//
//  CoreMeasureViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 25/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "CoreMeasureViewController.h"
#import "Vaavud-Swift.h"
#import "SavingWindMeasurementController.h"

@interface CoreMeasureViewController ()

@property (nonatomic, weak) IBOutlet UILabel *averageHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel *currentHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel *unitHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionHeadingLabel;

@property (nonatomic, weak) IBOutlet UILabel *actualLabel;
@property (nonatomic, weak) IBOutlet UILabel *averageLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxLabel;
@property (nonatomic, weak) IBOutlet UILabel *informationTextLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *statusBar;
@property (weak, nonatomic) IBOutlet UILabel *directionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *directionImageView;

@property (nonatomic, weak) IBOutlet UIButton *startStopButton;
@property (nonatomic, weak) IBOutlet UIButton *unitButton;

@property (nonatomic, weak) IBOutlet UIView *graphContainer;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomLayoutGuideConstraint;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsBarButtonItem;

@end

@implementation CoreMeasureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[self.settingsBarButtonItem setTitle:NSLocalizedString(@"SETTINGS_TITLE", nil)];
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //NSLog(@"[CoreMeasureViewController] topLayoutGuide=%f", self.topLayoutGuide.length);
    //NSLog(@"[CoreMeasureViewController] bottomLayoutGuide=%f", self.bottomLayoutGuide.length);
    
    // note: hack for content view underlapping tab view when clicking on another tab and back
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") && (self.bottomLayoutGuideConstraint != nil)) {
        //self.edgesForExtendedLayout = UIRectEdgeNone;
        
        //NSLog(@"[CoreMeasureViewController] bottomLayoutGuide=%f", self.bottomLayoutGuide.length);
        
        [self.view removeConstraint:self.bottomLayoutGuideConstraint];
        self.bottomLayoutGuideConstraint = nil;
        
        NSLayoutConstraint *bottomSpaceConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:self.startStopButton
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                multiplier:1.0
                                                                                  constant:self.bottomLayoutGuide.length + 15.0];
        [self.view addConstraint:bottomSpaceConstraint];
    }
}

- (IBAction)startStopButtonPushed:(id)sender {
    [super startStopButtonPushed:sender];
}

- (IBAction)unitButtonPushed:(id)sender {
    [super unitButtonPushed:sender];
}

- (void)measurementStopped:(MeasurementSession *)measurementSession {
    [super measurementStopped:measurementSession];
    [self windchillForSession:measurementSession];
}

- (NSNumber *)windchillForSession:(MeasurementSession *)session {
    NSNumber *temperatureNumber = session.sourcedTemperature;
    if (!temperatureNumber) {
        return nil;
    }
    
    double temperature = temperatureNumber.doubleValue - 273.15;
    
    NSNumber *windspeedNumber = session.windSpeedAvg ?: session.sourcedWindSpeedAvg;
    if (!windspeedNumber) {
        return nil;
    }
    
    double windspeed = windspeedNumber.doubleValue*3.6;
    
    if (temperature > 10 || windspeed < 4.8) {
        return nil;
    }
    
    double k = 13.12;
    double a = 0.6215;
    double b = -11.37;
    double c = 0.3965;
    double d = 0.16;
    
    double wci = k + a*temperature + b*pow(windspeed, d) + c*temperature*pow(windspeed, d);
    
    NSLog(@"wci: %f", wci);

    return @(wci);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SummaryFromMeasureSegue"]) {
        CoreSummaryViewController *destination = segue.destinationViewController;
        destination.session = self.concludedSession;
        self.concludedSession = nil;
    }
}

@end
