//
//  MeasureViewController.m
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "MeasureViewController.h"
#import "Property+Util.h"
#import "UnitUtil.h"
#import "TermsViewController.h"
#import "UIColor+VaavudColors.h"
#import "Mixpanel.h"
#import "MeasurementSession+Util.h"
#import "ImageUtil.h"
#import "AccountManager.h"
#import "ShareDialog.h"
#import "ServerUploadManager.h"
#import "vaavudGraphHostingView.h"
#import "UnitUtil.h"
#import <math.h>
#import <FacebookSDK/FacebookSDK.h>

@interface MeasureViewController ()

@property (nonatomic) BOOL buttonShowsStart;

@property (nonatomic, strong) NSTimer *statusBarTimer;
@property (nonatomic, strong) CADisplayLink *displayLinkGraphUI;
@property (nonatomic, strong) CADisplayLink *displayLinkGraphValues;
@property (nonatomic, strong) VaavudCoreController *vaavudCoreController;
@property (nonatomic, strong) NSArray *compassTableShort;

@property (nonatomic) BOOL isValid;

@property (nonatomic) WindSpeedUnit windSpeedUnit;

@property (nonatomic) NSNumber *actualLabelCurrentValue;
@property (nonatomic) NSNumber *averageLabelCurrentValue;
@property (nonatomic) NSNumber *maxLabelCurrentValue;

@property (nonatomic,strong) UIView *customDimmingView;
@property (nonatomic,strong) ShareDialog *shareDialog;
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation MeasureViewController {
    
}

- (UILabel*) averageHeadingLabel {
    return nil;
}

- (UILabel*) currentHeadingLabel {
    return nil;
}

- (UILabel*) maxHeadingLabel {
    return nil;
}

- (UILabel*) unitHeadingLabel {
    return nil;
}

- (UILabel*) actualLabel {
    return nil;
}

- (UILabel*) averageLabel {
    return nil;
}

- (UILabel*) maxLabel {
    return nil;
}

- (UILabel*) temperatureHeadingLabel {
    return nil;
}

- (UILabel*) temperatureLabel {
    return nil;
}

- (UILabel*) informationTextLabel {
    return nil;
}

- (UIProgressView*) statusBar {
    return nil;
}

- (UIButton*) startStopButton {
    return nil;
}

- (UIButton*) unitButton {
    return nil;
}

- (vaavudGraphHostingView*) graphHostView {
    return nil;
}

- (void) viewDidLoad {
    [super viewDidLoad];

    self.windSpeedUnit = -1; // make sure windSpeedUnit is updated in viewWillAppear by setting it to an invalid value
    self.shareToFacebook = YES;
    
    if (self.averageHeadingLabel) {
        self.averageHeadingLabel.text = [NSLocalizedString(@"HEADING_AVERAGE", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    if (self.currentHeadingLabel) {
        self.currentHeadingLabel.text = [NSLocalizedString(@"HEADING_CURRENT", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    if (self.maxHeadingLabel) {
        self.maxHeadingLabel.text = [NSLocalizedString(@"HEADING_MAX", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    if (self.unitHeadingLabel) {
        self.unitHeadingLabel.text = [NSLocalizedString(@"HEADING_UNIT", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    if (self.temperatureHeadingLabel) {
        self.temperatureHeadingLabel.text = [NSLocalizedString(@"HEADING_TEMPERATURE", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
        self.lookupTemperature = YES;
    }
    else {
        self.lookupTemperature = NO;
    }
    
    if (self.graphHostView) {
        [self.graphHostView setupCorePlotGraph];
    }
    
    self.compassTableShort = [NSArray arrayWithObjects:@"N",@"NE",@"E",@"SE",@"S",@"SW",@"W",@"NW", nil];

    // Set correct font text colors
    UIColor *vaavudBlueUIcolor = [UIColor vaavudColor];
    
    if (self.actualLabel) {
        self.actualLabel.textColor = vaavudBlueUIcolor;
    }
    
    if (self.maxLabel) {
        self.maxLabel.textColor = vaavudBlueUIcolor;
    }
    
    if (self.unitButton) {
        [self.unitButton setTitleColor:vaavudBlueUIcolor forState:UIControlStateNormal];
    }
    
    if (self.statusBar) {
        self.statusBar.progressTintColor = vaavudBlueUIcolor;
    }
    
    self.buttonShowsStart = YES;
    
    if (self.startStopButton) {
        [self.startStopButton setTitle:NSLocalizedString(@"BUTTON_START", nil) forState:UIControlStateNormal];
        self.startStopButton.backgroundColor = vaavudBlueUIcolor;
        self.startStopButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
        self.startStopButton.layer.masksToBounds = YES;
    }

#ifdef AGRI
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"agri-logo.png"]];

#elif CORE
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]];

#endif
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [[VEVaavudElectronicSDK sharedVaavudElectronic] addListener:self];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    WindSpeedUnit newWindSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    if (newWindSpeedUnit != self.windSpeedUnit) {
        self.windSpeedUnit = newWindSpeedUnit;
        
        if (self.unitButton) {
            [self.unitButton setTitle:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit] forState:UIControlStateNormal];
        }
        
        [self updateLabelsFromCurrentValues];
        
        if (self.graphHostView) {
            // note: for some reason the y-axis is not changed correctly the first time, so we call the following method twice
            [self.graphHostView changeWindSpeedUnit:self.windSpeedUnit];
            [self.graphHostView changeWindSpeedUnit:self.windSpeedUnit];
        }
    }

    if (self.graphHostView) {
        [self.graphHostView resumeUpdates];
    }
    
    if (!self.buttonShowsStart) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Measure Screen"];
    }
}

- (void) tabSelected {
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Measure Tab"];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.graphHostView pauseUpdates];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void) start {
    
    self.buttonShowsStart = NO;
    
    if (self.startStopButton) {
        self.startStopButton.backgroundColor = [UIColor vaavudRedColor];
        [self.startStopButton setTitle:NSLocalizedString(@"BUTTON_STOP", nil) forState:UIControlStateNormal];
    }

    if (self.statusBar) {
        [self.statusBar setProgress:0];
    }
    
    self.vaavudCoreController = [[VaavudCoreController alloc] init];
    self.vaavudCoreController.lookupTemperature = self.lookupTemperature;
    self.vaavudCoreController.vaavudCoreControllerViewControllerDelegate = self; // set the core controller's view controller delegate to self (reports when meassurements are valid)
    
    if (self.graphHostView) {
        self.graphHostView.vaavudCoreController = self.vaavudCoreController;
        [self.graphHostView setupCorePlotGraph];
    }
    
    self.actualLabelCurrentValue = nil;
    self.averageLabelCurrentValue = nil;
    self.maxLabelCurrentValue = nil;
    [self updateLabelsFromCurrentValues];
    
    [self.vaavudCoreController start];
    self.statusBarTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateLabels) userInfo:nil repeats:YES];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (NSTimeInterval) stop:(BOOL)onlyUI {
    self.buttonShowsStart = YES;
    
    if (self.startStopButton) {
        self.startStopButton.backgroundColor = [UIColor vaavudColor];
        [self.startStopButton setTitle:NSLocalizedString(@"BUTTON_START", nil) forState:UIControlStateNormal];
    }

    [self.displayLinkGraphUI invalidate];
    [self.displayLinkGraphValues invalidate];
    
    if (self.statusBarTimer) {
        [self.statusBarTimer invalidate];
        self.statusBarTimer = nil;
    }
    
    NSTimeInterval durationSeconds = 0.0;
    if (!onlyUI) {
        durationSeconds = [self.vaavudCoreController stop];
    }
    
    if (self.informationTextLabel) {
        self.informationTextLabel.text = @"";
    }
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    return durationSeconds;
}

/*
 * Called from VaavudCoreController if:
 * (1) the measurement session is deleted while measuring
 * (2) the measurement session's "measuring" flag turns to NO while measuring
 *     - which will be the case if ServerUploadManager sees a long period of inactivity
 */
- (void) measuringStoppedByModel {
    [self stop:YES];
}

- (void) windSpeedMeasurementsAreValid:(BOOL)valid {
    self.isValid = valid;
    
    if (!valid) {
        [self.displayLinkGraphUI invalidate];
        [self.displayLinkGraphValues invalidate];
    }
    else {
        if (self.graphHostView) {
            [self.graphHostView createNewPlot];
        }
        
        self.displayLinkGraphUI = [CADisplayLink displayLinkWithTarget:self.graphHostView selector:@selector(shiftGraphX)];
        self.displayLinkGraphUI.frameInterval = 10; // SET VALUE HIGHER FOR IPHONE 4
        
        self.displayLinkGraphValues = [CADisplayLink displayLinkWithTarget:self.graphHostView selector:@selector(addDataPoint)];
        self.displayLinkGraphValues.frameInterval = 10; // SET VALUE HIGHER FOR IPHONE 4
        
        [self.displayLinkGraphUI addToRunLoop:[NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];
        [self.displayLinkGraphValues addToRunLoop:[NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];
    }
}

- (void) updateMeasuredValues:(NSNumber*)windSpeedAvg windSpeedMax:(NSNumber*)windSpeedMax {
    self.averageLabelCurrentValue = windSpeedAvg;
    self.maxLabelCurrentValue = windSpeedMax;
    [self updateLabelsFromCurrentValues];
}

- (void) updateLabels {    
    
    if (self.isValid) {
        self.actualLabelCurrentValue = [self.vaavudCoreController.windSpeed lastObject];
        self.averageLabelCurrentValue = [self.vaavudCoreController getAverage];
        self.maxLabelCurrentValue = [self.vaavudCoreController getMax];
        
        if (self.informationTextLabel) {
            self.informationTextLabel.text = NSLocalizedString(@"INFO_MEASURING", nil);
        }
        
        if (self.statusBar) {
            [self.statusBar setProgress:[[self.vaavudCoreController getProgress] floatValue]];
        }
    }
    else {
        self.actualLabelCurrentValue = nil;
        
        if (self.informationTextLabel) {
            if (self.vaavudCoreController.dynamicsIsValid) {
                self.informationTextLabel.text = NSLocalizedString(@"INFO_NO_SIGNAL", nil);
            }
            else {
                self.informationTextLabel.text = NSLocalizedString(@"INFO_KEEP_STEADY", nil);
            }
        }
    }

    [self updateLabelsFromCurrentValues];
}

- (void) updateLabelsFromCurrentValues {
    if (self.actualLabel && self.actualLabelCurrentValue != nil && !isnan([self.actualLabelCurrentValue doubleValue])) {
        self.actualLabel.text = [self formatValue:[UnitUtil displayWindSpeedFromDouble:[self.actualLabelCurrentValue doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        self.actualLabel.text = @"-";
    }
    
    if (self.averageLabel && self.averageLabelCurrentValue != nil && !isnan([self.averageLabelCurrentValue doubleValue])) {
        self.averageLabel.text = [self formatValue:[UnitUtil displayWindSpeedFromDouble:[self.averageLabelCurrentValue doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        self.averageLabel.text = @"-";
    }
    
    if (self.maxLabel && self.maxLabelCurrentValue != nil && !isnan([self.maxLabelCurrentValue doubleValue])) {
        self.maxLabel.text = [self formatValue:[UnitUtil displayWindSpeedFromDouble:[self.maxLabelCurrentValue doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        self.maxLabel.text = @"-";
    }
}

- (void) temperatureUpdated:(float)temperature {
    if (self.temperatureLabel) {
        self.temperatureLabel.text = [self formatValue:temperature - 273.15F];
    }
}

- (NSString*) formatValue:(double) value {
    if (value > 100.0) {
        return [NSString stringWithFormat: @"%.0f", value];
    }
    else {
        return [NSString stringWithFormat: @"%.1f", value];
    }
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        self.vaavudCoreController.upsideDown = NO;
    }
    
    if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        self.vaavudCoreController.upsideDown = YES;
    }
}

- (IBAction) startStopButtonPushed:(id)sender {
    
    if (self.buttonShowsStart) {
        [self start];
        
        if ([Property isMixpanelEnabled]) {
            Mixpanel *mixpanel = [Mixpanel sharedInstance];

            NSInteger measurementCount = [MeasurementSession MR_countOfEntities];
            NSInteger realMeasurementCount = [MeasurementSession MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"windSpeedAvg > 0"]];
            [mixpanel registerSuperProperties:@{@"Measurements":[NSNumber numberWithInteger:measurementCount], @"Real Measurements":[NSNumber numberWithInteger:realMeasurementCount]}];
            
            [mixpanel track:@"Start Measurement"];
        }
    }
    else {
        NSTimeInterval durationSecounds = [self stop:NO];

        if ([Property isMixpanelEnabled]) {

            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            
            NSInteger measurementCount = [MeasurementSession MR_countOfEntities];
            NSInteger realMeasurementCount = [MeasurementSession MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"windSpeedAvg > 0"]];
            [mixpanel registerSuperProperties:@{@"Measurements":[NSNumber numberWithInteger:measurementCount], @"Real Measurements":[NSNumber numberWithInteger:realMeasurementCount]}];
            
            if (self.averageLabelCurrentValue && ([self.averageLabelCurrentValue floatValue] > 0.0F) && self.maxLabelCurrentValue && ([self.maxLabelCurrentValue floatValue] > 0.0F)) {
                [mixpanel track:@"Stop Measurement" properties:@{@"Duration": [NSNumber numberWithInt:round(durationSecounds)], @"Avg Wind Speed": self.averageLabelCurrentValue, @"Max Wind Speed": self.maxLabelCurrentValue}];
            }
            else {
                [mixpanel track:@"Stop Measurement" properties:@{@"Duration": [NSNumber numberWithInt:round(durationSecounds)]}];
            }
        }
        
        [self promptForFacebookSharing];
        [Property refreshHasWindMeter];
    }
}

- (IBAction) unitButtonPushed:(id)sender {
    self.windSpeedUnit = [UnitUtil nextWindSpeedUnit:self.windSpeedUnit];
    [Property setAsInteger:[NSNumber numberWithInt:self.windSpeedUnit] forKey:KEY_WIND_SPEED_UNIT];

    [self.unitButton setTitle:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit] forState:UIControlStateNormal];
    [self updateLabelsFromCurrentValues];

    if (self.graphHostView) {
        // note: for some reason the y-axis is not changed correctly the first time, so we call the following method twice
        [self.graphHostView changeWindSpeedUnit:self.windSpeedUnit];
        [self.graphHostView changeWindSpeedUnit:self.windSpeedUnit];
    }
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void) promptForFacebookSharing {
    
    if (self.shareToFacebook && self.averageLabelCurrentValue && ([self.averageLabelCurrentValue floatValue] > 0.0F) && self.maxLabelCurrentValue && ([self.maxLabelCurrentValue floatValue] > 0.0F) && [ServerUploadManager sharedInstance].hasReachability && [Property getAsBoolean:KEY_ENABLE_SHARE_DIALOG defaultValue:YES]) {
        
        if ([Property isMixpanelEnabled]) {
            [[Mixpanel sharedInstance] track:@"Share Dialog"];
        }

        self.customDimmingView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tabBarController.view.bounds.size.width, self.tabBarController.view.bounds.size.height)];
        self.customDimmingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.customDimmingView.translatesAutoresizingMaskIntoConstraints = YES;
        self.customDimmingView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.0];
        [self.tabBarController.view addSubview:self.customDimmingView];
        
        NSArray* topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"ShareDialog" owner:self options:nil];
        self.shareDialog = (ShareDialog*) [topLevelObjects objectAtIndex:0];
        self.shareDialog.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        self.shareDialog.translatesAutoresizingMaskIntoConstraints = YES;
        self.shareDialog.frame = CGRectMake((self.customDimmingView.bounds.size.width - SHARE_DIALOG_WIDTH) / 2.0, 40.0, SHARE_DIALOG_WIDTH, SHARE_DIALOG_HEIGHT_NO_PICTURES);
        self.shareDialog.layer.cornerRadius = DIALOG_CORNER_RADIUS;
        self.shareDialog.layer.masksToBounds = YES;
        self.shareDialog.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.95];
        self.shareDialog.textView.layer.cornerRadius = FORM_CORNER_RADIUS;
        self.shareDialog.textView.layer.masksToBounds = YES;
        self.shareDialog.delegate = self;
        self.shareDialog.hidden = YES;
        [self.customDimmingView addSubview:self.shareDialog];
        [self.shareDialog.textView becomeFirstResponder];
        
        [UIView animateWithDuration:0.2 animations:^{
            self.customDimmingView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.4];
            self.shareDialog.hidden = NO;
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void) startShareActivityIndicator {
    if (self.shareDialog && self.customDimmingView) {
        [self.shareDialog.textView resignFirstResponder];
        self.shareDialog.hidden = YES;
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = YES;
        self.activityIndicatorView.frame = CGRectMake(self.customDimmingView.bounds.size.width / 2.0 - self.activityIndicatorView.bounds.size.width / 2.0,
                                self.customDimmingView.bounds.size.height / 2.0 - self.activityIndicatorView.bounds.size.height / 2.0,
                                self.activityIndicatorView.bounds.size.width,
                                self.activityIndicatorView.bounds.size.height);
        [self.customDimmingView addSubview:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
    }
}

- (void) shareSuccessful:(BOOL)hasMessage numberOfPhotos:(NSInteger)numberOfPhotos {
    [self dismissShareDialog];

    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Share Dialog Successful" properties:@{@"Message": (hasMessage ? @"true" : @"false"), @"Photos": [NSNumber numberWithInteger:numberOfPhotos]}];
    }
}

- (void) shareFailure {
    [self dismissShareDialog];
    
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Share Dialog Failure"];
    }
}

- (void) shareCancelled {
    [self dismissShareDialog];

    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Share Dialog Cancelled"];
    }
}

- (void) dismissShareDialog {
    [self.shareDialog.textView resignFirstResponder];
    [UIView animateWithDuration:0.2 animations:^{
        self.customDimmingView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.0];
        self.shareDialog.hidden = YES;
    } completion:^(BOOL finished) {
        [self.shareDialog removeFromSuperview];
        [self.customDimmingView removeFromSuperview];
        self.shareDialog = nil;
        self.customDimmingView = nil;
        self.activityIndicatorView = nil;
    }];
}

- (void) presentViewControllerFromShareDialog:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void) dismissViewControllerFromShareDialog {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (double) shareAvgSpeed {
    return [UnitUtil displayWindSpeedFromDouble:[self.averageLabelCurrentValue doubleValue] unit:self.windSpeedUnit];
}

- (double) shareMaxSpeed {
    return [UnitUtil displayWindSpeedFromDouble:[self.maxLabelCurrentValue doubleValue] unit:self.windSpeedUnit];
}

- (NSNumber*) shareLatitude {
    return self.vaavudCoreController.currentLatitude;
}

- (NSNumber*) shareLongitude {
    return self.vaavudCoreController.currentLongitude;
}

- (NSString*) shareUnit {
    return [UnitUtil englishDisplayNameForWindSpeedUnit:self.windSpeedUnit];
}

/* Vaavud Electronic */

- (void) devicePlugedInChecking {
    NSLog(@"devicePlugedInChecking");
}

- (void) notVaavudPlugedIn {
    NSLog(@"notVaavudPlugedIn");
}

- (void) vaavudPlugedIn {
    NSLog(@"vaavudPlugedIn");
}

- (void) deviceWasUnpluged {
    NSLog(@"deviceWasUnpluged");
}

@end
