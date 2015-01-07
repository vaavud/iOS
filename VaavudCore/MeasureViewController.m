//
//  MeasureViewController.m
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#define minimumNumberOfSeconds 60
#define DISMISS_NOTIFICATION_AFTER 2.0

#import "MeasureViewController.h"
#import "MjolnirMeasurementController.h"
#import "SleipnirMeasurementController.h"
#import "SavingWindMeasurementController.h"
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
#import "GraphView.h"
#import "UnitUtil.h"
#import "MixpanelUtil.h"
#import "AppDelegate.h"
#import "LocationManager.h"
#import <math.h>
#import <FacebookSDK/FacebookSDK.h>

@interface MeasureViewController ()

@property (nonatomic) BOOL lookupTemperature;

@property (nonatomic) WindSpeedUnit windSpeedUnit;
@property (nonatomic) NSInteger directionUnit;

@property (nonatomic, strong) NSNumber *actualLabelCurrentValue;
@property (nonatomic, strong) NSNumber *averageLabelCurrentValue;
@property (nonatomic, strong) NSNumber *maxLabelCurrentValue;
@property (nonatomic, strong) NSNumber *directionLabelCurrentValue;
@property (nonatomic, strong) NSNumber *currentLatitude;
@property (nonatomic, strong) NSNumber *currentLongitude;
@property (nonatomic, strong) NSNumber *currentTemperature;
@property (nonatomic, strong) GraphView *graphView;

@property (nonatomic, strong) UIView *customDimmingView;
@property (nonatomic, strong) ShareDialog *shareDialog;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, strong) CADisplayLink *shiftGraphXTimer;
@property (nonatomic, strong) NSTimer *statusBarTimer;
@property (nonatomic, strong) NSDate *statusBarStartTime;

@property (nonatomic, strong) NSDate *lastValidityChangeTime;
@property (nonatomic) double nonValidDuration;
@property (nonatomic) BOOL isValid;

@property (nonatomic) BOOL useSleipnir;
@property (nonatomic, strong) UIAlertView *notificationView;
@property (nonatomic, strong) UIAlertController* notificationAlertViewController;
@property (nonatomic, strong) NSTimer *notificationTimer;

@end

@implementation MeasureViewController {}

/**** Storyboard Properties Specifiable by Subclasses ****/

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

- (UILabel*) directionHeadingLabel {
    return nil;
}

- (UILabel*) directionLabel {
    return nil;
}

- (UIImageView*) directionImageView {
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

- (UIView*) graphContainer {
    return nil;
}

/**** Setup ****/

- (void) viewDidLoad {
    [super viewDidLoad];

    self.windSpeedUnit = -1; // make sure windSpeedUnit is updated in viewWillAppear by setting it to an invalid value
    self.directionUnit = -1;
    self.shareToFacebook = YES;
    self.useSleipnir = [SleipnirMeasurementController sharedInstance].isDeviceConnected;
    
    self.averageLabelCurrentValue = nil;
    self.actualLabelCurrentValue = nil;
    self.maxLabelCurrentValue = nil;
    self.directionLabelCurrentValue = nil;
    
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
    if (self.directionHeadingLabel) {
        self.directionHeadingLabel.text = [NSLocalizedString(@"HEADING_WIND_DIRECTION", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    if (self.directionLabel) {
        self.directionLabel.text = @"-";
    }
    if (self.temperatureHeadingLabel) {
        self.temperatureHeadingLabel.text = [NSLocalizedString(@"HEADING_TEMPERATURE", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
        self.lookupTemperature = YES;
    }
    else {
        self.lookupTemperature = NO;
    }
    if (self.temperatureLabel) {
        self.temperatureLabel.text = @"-";
    }
    
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
    
    if (self.directionImageView) {
        self.directionImageView.hidden = YES;
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
    
    [self createGraphView];

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]];
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [SleipnirMeasurementController sharedInstance].delegate = self;
}

-(NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
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
        
        if (self.graphView) {
            [self.graphView changeWindSpeedUnit:self.windSpeedUnit];
        }
    }
    
    NSNumber *directionUnitNumber = [Property getAsInteger:KEY_DIRECTION_UNIT];
    NSInteger directionUnit = (directionUnitNumber) ? [directionUnitNumber doubleValue] : 0;
    if (self.directionUnit != directionUnit) {
        self.directionUnit = directionUnit;
        [self updateDirectionFromCurrentValue];
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
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void) reset {
    
    if (!self.buttonShowsStart) {
        [self stop];
    }

    // reset labels, status bar, and graph...
    
    if (self.statusBar) {
        [self.statusBar setProgress:0];
        self.statusBarStartTime = [NSDate date];
    }
    
    self.actualLabelCurrentValue = nil;
    self.averageLabelCurrentValue = nil;
    self.maxLabelCurrentValue = nil;
    self.directionLabelCurrentValue = nil;
    self.currentTemperature = nil;
    self.lastValidityChangeTime = [NSDate date];
    self.nonValidDuration = 0.0;
    self.isValid = YES;
    [self updateLabelsFromCurrentValues];
    [self updateDirectionFromCurrentValue];
    self.temperatureLabel.text = @"-";
    
    if (self.graphContainer) {
        [self createGraphView];
    }
}

/**** Common Start/Stop Measuring ****/

- (IBAction) startStopButtonPushed:(id)sender {
    
    if (self.buttonShowsStart) {
        [self startWithUITracking:YES];
    }
    else {
        [self stopWithUITracking:YES action:@"Button"];
    }
}

// for subclasses
- (void) start {
    [self startWithUITracking:YES];
}

// for subclasses
- (void) stop {
    [self stopWithUITracking:YES action:@"Button"];
}

- (NSString*) stopButtonTitle {
    return NSLocalizedString(@"BUTTON_STOP", nil);
}

- (void) startWithUITracking:(BOOL)uiTracking {
    
    if (!self.buttonShowsStart) {
        // already stopped
        return;
    }

    // this does nothing if location services are already started, but otherwise it will prompt the user to allow
    // vaavud to use location if we're not already allowed
    
    [[LocationManager sharedInstance] start];
    
    // update start/stop button text...
    
    self.buttonShowsStart = NO;
    
    if (self.startStopButton) {
        self.startStopButton.backgroundColor = [UIColor vaavudRedColor];
        [self.startStopButton setTitle:[self stopButtonTitle] forState:UIControlStateNormal];
    }
    
    // reset labels, status bar, and graph...
    
    if (self.statusBar) {
        [self.statusBar setProgress:0];
        self.statusBarStartTime = [NSDate date];
    }
    
    self.actualLabelCurrentValue = nil;
    self.averageLabelCurrentValue = nil;
    self.maxLabelCurrentValue = nil;
    self.directionLabelCurrentValue = nil;
    self.currentTemperature = nil;
    self.lastValidityChangeTime = [NSDate date];
    self.nonValidDuration = 0.0;
    self.isValid = YES;
    [self updateLabelsFromCurrentValues];
    [self updateDirectionFromCurrentValue];
    self.temperatureLabel.text = @"-";

    if (self.graphContainer) {
        [self createGraphView];
    }

    // make sure the display doesn't turn off during measuring...
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    // select hardware controller...
    
    WindMeasurementController *hardwareController;
    
    if (self.useSleipnir) {
        hardwareController = [SleipnirMeasurementController sharedInstance];
    }
    else {
        hardwareController = [[MjolnirMeasurementController alloc] init];
    }
    
    // start measuring...
    
    if (!self.privacy) {
        self.privacy = [NSNumber numberWithInt:1];
    }
    
    SavingWindMeasurementController *controller = [SavingWindMeasurementController sharedInstance];
    controller.lookupTemperature = self.lookupTemperature;
    controller.privacy = self.privacy;
    controller.delegate = self;
    [controller setHardwareController:hardwareController];
    [controller start];
    
    // add timer that auto-scrolls the x-axis...
    
    if (self.graphView) {
        self.shiftGraphXTimer = [CADisplayLink displayLinkWithTarget:self.graphView selector:@selector(shiftGraphX)];
        self.shiftGraphXTimer.frameInterval = 5;
        [self.shiftGraphXTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];
    }

    // add timer that updates the progress bar...
    
    self.statusBarTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateStatusBar) userInfo:nil repeats:YES];
    self.isMinimumThresholdReached = NO;

    // Mixpanel tracking...
    
    if (uiTracking) {
        if ([Property isMixpanelEnabled]) {
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Start Measurement" properties:@{@"Wind Meter": [controller mixpanelWindMeterName]}];
        }
    }
    
    [self measurementStarted];
}

// for subclasses
- (void) measurementStarted {
}

- (void) stopWithUITracking:(BOOL)uiTracking action:(NSString*)action {
    
    if (self.buttonShowsStart) {
        // already stopped
        return;
    }
    
    // update start/stop button text...
    
    self.buttonShowsStart = YES;
    
    if (self.startStopButton) {
        self.startStopButton.backgroundColor = [UIColor vaavudColor];
        [self.startStopButton setTitle:NSLocalizedString(@"BUTTON_START", nil) forState:UIControlStateNormal];
    }
    
    if (self.informationTextLabel) {
        self.informationTextLabel.text = @"";
    }
    
    // allow display to turn off again...
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    // stop timers...
    
    if (self.shiftGraphXTimer) {
        [self.shiftGraphXTimer invalidate];
        self.shiftGraphXTimer = nil;
    }
    
    if (self.statusBarTimer) {
        [self.statusBarTimer invalidate];
        self.statusBarTimer = nil;
    }

    // stop measuring...
    
    SavingWindMeasurementController *controller = [SavingWindMeasurementController sharedInstance];
    
    NSTimeInterval durationSecounds = [controller stop];
    [controller clearHardwareController];
    
    // refresh whether the user has a wind meter...
    
    [Property refreshHasWindMeter];

    // this will only be false if we were stopped by the model (e.g. measurement deleted while measuring)
    if (uiTracking) {

        // Mixpanel tracking...
        
        if ([Property isMixpanelEnabled]) {
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [MixpanelUtil updateMeasurementProperties:NO];
            
            if (self.averageLabelCurrentValue && ([self.averageLabelCurrentValue floatValue] > 0.0F) && self.maxLabelCurrentValue && ([self.maxLabelCurrentValue floatValue] > 0.0F)) {
                [mixpanel track:@"Stop Measurement" properties:@{@"Action": action, @"Wind Meter": [controller mixpanelWindMeterName], @"Duration": [NSNumber numberWithInt:round(durationSecounds)], @"Avg Wind Speed": self.averageLabelCurrentValue, @"Max Wind Speed": self.maxLabelCurrentValue}];
            }
            else {
                [mixpanel track:@"Stop Measurement" properties:@{@"Action": action, @"Wind Meter": [controller mixpanelWindMeterName], @"Duration": [NSNumber numberWithInt:round(durationSecounds)]}];
            }
        }
        
        MeasurementSession *session = [controller getLatestMeasurementSession];
        if (session) {
            [self measurementStopped:session];
        }
        
        // check if we were called from another app and return to it if so...
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.xCallbackSuccess && appDelegate.xCallbackSuccess != nil && appDelegate.xCallbackSuccess != (id)[NSNull null] && [appDelegate.xCallbackSuccess length] > 0) {
            
            NSLog(@"[VaavudCoreController] There is a pending x-success callback: %@", appDelegate.xCallbackSuccess);
            
            // TODO: this will return to the caller too quickly before we're fully uploaded to own servers
            NSString* callbackURL = [NSString stringWithFormat:@"%@?windSpeedAvg=%@&windSpeedMax=%@", appDelegate.xCallbackSuccess, self.averageLabelCurrentValue, self.maxLabelCurrentValue];
            appDelegate.xCallbackSuccess = nil;
            
            NSLog(@"[VaavudCoreController] Trying to open callback URL: %@", callbackURL);
            
            BOOL success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:callbackURL]];
            if (!success) {
                NSLog(@"Failed to open callback URL");
            }
        }
        else {

            // potentially popup Facebook share dialog...
            
            [self promptForFacebookSharing];
        }
    }
}

// for subclasses
- (void) measurementStopped:(MeasurementSession*)measurementSession {
}

/*
 * Called from VaavudCoreController if:
 * (1) the measurement session is deleted while measuring
 * (2) the measurement session's "measuring" flag turns to NO while measuring
 *     - which will be the case if ServerUploadManager sees a long period of inactivity
 */
- (void) measuringStoppedByModel {
    [self stopWithUITracking:NO action:@"Model"];
}

- (void) createGraphView {
    
    if (self.graphContainer) {
    
        [self destroyGraphView];
        
        self.graphView = [[GraphView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.graphContainer.frame.size.width, self.graphContainer.frame.size.height) windSpeedUnit:self.windSpeedUnit];
        self.graphView.autoresizesSubviews = YES;
        self.graphView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.graphContainer addSubview:self.graphView];
    }
}

- (void) destroyGraphView {
    
    if (self.graphContainer && self.graphView) {
        [self.graphView removeFromSuperview];
        self.graphView = nil;
    }
}

- (void) addSpeedMeasurement:(NSNumber*)currentSpeed avgSpeed:(NSNumber*)avgSpeed maxSpeed:(NSNumber*)maxSpeed {
    
    //NSLog(@"[MeasurementViewController] Adding measurement, current=%@, avg=%@, max=%@", currentSpeed, avgSpeed, maxSpeed);
    
    self.actualLabelCurrentValue = currentSpeed;
    self.averageLabelCurrentValue = avgSpeed;
    self.maxLabelCurrentValue = maxSpeed;
    [self updateLabelsFromCurrentValues];
    
    // only update graph if we're measuring
    if (self.graphView && !self.buttonShowsStart) {
        [self.graphView addPoint:[NSDate date] currentSpeed:currentSpeed averageSpeed:avgSpeed];
    }
}

- (void) updateDirection:(NSNumber*)avgDirection {
    
    self.directionLabelCurrentValue = avgDirection;
    [self updateDirectionFromCurrentValue];
}

- (void) updateDirectionLocal:(NSNumber *)direction {
    if (self.directionImageView) {
        
        self.directionImageView.image = [UIImage imageNamed:@"wind_arrow.png"];
        if (self.directionImageView.image) {
            self.directionImageView.transform = CGAffineTransformMakeRotation([direction doubleValue]/180 * M_PI);
            self.directionImageView.hidden = NO;
        }
        else {
            self.directionImageView.hidden = YES;
        }
    }
}



/**** Sleipnir Measurement ****/

- (void) deviceAvailabilityChanged:(enum WindMeterDeviceType) device andAvailability: (BOOL) available {
    if (device == SleipnirWindMeterDeviceType) {
        self.useSleipnir = available;
    }
}

- (void) deviceConnected:(enum WindMeterDeviceType)device {
    
    if (device == SleipnirWindMeterDeviceType) {
        if (!self.useSleipnir && !self.buttonShowsStart) {
            
            // measurement with Mjolnir is in progress when Sleipnir is plugged in, so stop it
            [self stopWithUITracking:NO action:@"Plug"];
        }
        
        [self showNotification:NSLocalizedString(@"DEVICE_CONNECTED_TITLE", nil) message:NSLocalizedString(@"DEVICE_CONNECTED_MESSAGE", nil) dismissAfter:DISMISS_NOTIFICATION_AFTER];
    }
    else if (device == UnknownWindMeterDeviceType) {

        [self showNotification:NSLocalizedString(@"UNKNOWN_DEVICE_CONNECTED_TITLE", nil) message:NSLocalizedString(@"UNKNOWN_DEVICE_CONNECTED_MESSAGE", nil) dismissAfter:DISMISS_NOTIFICATION_AFTER];
    }
}

- (void) deviceDisconnected:(enum WindMeterDeviceType)device {
    
    if (device == SleipnirWindMeterDeviceType) {
        if (!self.buttonShowsStart) {
            [self stopWithUITracking:YES action:@"Unplug"];
        }
        
        [self showNotification:NSLocalizedString(@"DEVICE_DISCONNECTED_TITLE", nil) message:NSLocalizedString(@"DEVICE_DISCONNECTED_MESSAGE", nil) dismissAfter:DISMISS_NOTIFICATION_AFTER];
    }
    else if (device == UnknownWindMeterDeviceType) {
        
        [self showNotification:NSLocalizedString(@"UNKNOWN_DEVICE_DISCONNECTED_TITLE", nil) message:NSLocalizedString(@"UNKNOWN_DEVICE_DISCONNECTED_MESSAGE", nil) dismissAfter:DISMISS_NOTIFICATION_AFTER];
    }
}

- (void) showNotification:(NSString*)title message:(NSString*)message dismissAfter:(NSTimeInterval)time {
    
    if (self.notificationTimer) {
        [self.notificationTimer invalidate];
        self.notificationTimer = nil;
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        
        if (self.notificationAlertViewController) {
            [self dismissViewControllerAnimated:NO completion:nil];
            self.notificationAlertViewController = nil;
        }

        self.notificationAlertViewController = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [self presentViewController:self.notificationAlertViewController animated:YES completion:nil];
    }
    else {
        if (self.notificationView) {
            [self.notificationView dismissWithClickedButtonIndex:0 animated:NO];
            self.notificationView = nil;
        }
        
        self.notificationView = [[UIAlertView alloc] initWithTitle:title
                                                           message:message
                                                          delegate:nil
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:nil];
        [self.notificationView show];
    }
    
    self.notificationTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(dismissNotification) userInfo:nil repeats:NO];
}

- (void) dismissNotification {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        if (self.notificationAlertViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
            self.notificationAlertViewController = nil;
        }
    }
    else {
        if (self.notificationView) {
            [self.notificationView dismissWithClickedButtonIndex:0 animated:YES];
            self.notificationView = nil;
        }
    }
    
    self.notificationTimer = nil;
}

/**** Mjolnir Measurement ****/

- (void) changedValidity:(BOOL)isValid dynamicsIsValid:(BOOL)dynamicsIsValid {
    
    NSDate *now = [NSDate date];
    
    if (isValid) {

        if (!self.isValid) {
            self.nonValidDuration += [now timeIntervalSinceDate:self.lastValidityChangeTime];
        }
        
        if (self.informationTextLabel) {
            self.informationTextLabel.text = NSLocalizedString(@"INFO_MEASURING", nil);
        }
    }
    else {

        if (self.isValid) {
            self.lastValidityChangeTime = now;
        }
        
        self.actualLabelCurrentValue = nil;

        if (self.informationTextLabel) {
            if (dynamicsIsValid) {
                self.informationTextLabel.text = NSLocalizedString(@"INFO_NO_SIGNAL", nil);
            }
            else {
                self.informationTextLabel.text = NSLocalizedString(@"INFO_KEEP_STEADY", nil);
            }
        }
        
        if (self.graphView) {
            [self.graphView newPlot];
        }
    }
    
    self.isValid = isValid;
    
    [self updateLabelsFromCurrentValues];
}

/**** Common Measurement Values Update ****/

- (void) updateLabelsFromCurrentValues {
    if (self.actualLabel && self.actualLabelCurrentValue && !isnan([self.actualLabelCurrentValue doubleValue])) {
        self.actualLabel.text = [self formatValue:[UnitUtil displayWindSpeedFromDouble:[self.actualLabelCurrentValue doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        self.actualLabel.text = @"-";
    }
    
    if (self.averageLabel && self.averageLabelCurrentValue && !isnan([self.averageLabelCurrentValue doubleValue])) {
        self.averageLabel.text = [self formatValue:[UnitUtil displayWindSpeedFromDouble:[self.averageLabelCurrentValue doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        self.averageLabel.text = @"-";
    }
    
    if (self.maxLabel && self.maxLabelCurrentValue && !isnan([self.maxLabelCurrentValue doubleValue])) {
        self.maxLabel.text = [self formatValue:[UnitUtil displayWindSpeedFromDouble:[self.maxLabelCurrentValue doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        self.maxLabel.text = @"-";
    }
}

- (void) updateDirectionFromCurrentValue {

    if (self.directionLabelCurrentValue && !isnan([self.directionLabelCurrentValue doubleValue])) {
        
        if (self.directionLabel) {
            if (self.directionUnit == 0) {
                self.directionLabel.text = [UnitUtil displayNameForDirection:self.directionLabelCurrentValue];
            }
            else {
                self.directionLabel.text = [NSString stringWithFormat:@"%@°", [NSNumber numberWithInt:(int)round([self.directionLabelCurrentValue doubleValue])]];
            }
        }
    }
    else {
        if (self.directionLabel) {
            self.directionLabel.text = @"-";
        }
        if (self.directionImageView) {
            self.directionImageView.hidden = YES;
        }
    }
}

- (void) updateTemperature:(NSNumber*)temperature {
    
    //NSLog(@"[MeasureViewController] Got temperature %@", temperature);
    
    self.currentTemperature = temperature;
    if (self.temperatureLabel && temperature) {
        self.temperatureLabel.text = [self formatValue:[temperature floatValue] - KELVIN_TO_CELCIUS];
    }
}

- (void) updateLocation:(NSNumber*)latitude longitude:(NSNumber*)longitude {
    if (latitude && longitude) {
        self.currentLatitude = latitude;
        self.currentLongitude = longitude;
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

- (void) updateStatusBar {
    if (self.statusBar && self.isValid) {
        float timeSinceStart = MAX(0.0, -[self.statusBarStartTime timeIntervalSinceNow] - self.nonValidDuration);
        double progress = timeSinceStart / minimumNumberOfSeconds;
        if (progress > 1.0) {
            progress = 1.0;
            if (!self.isMinimumThresholdReached) {
                self.isMinimumThresholdReached = YES;
                [self minimumThresholdReached];
            }
        }
        [self.statusBar setProgress:progress];
    }
}

// for subclasses
- (void) minimumThresholdReached {
}

- (IBAction) unitButtonPushed:(id)sender {
    self.windSpeedUnit = [UnitUtil nextWindSpeedUnit:self.windSpeedUnit];
    [Property setAsInteger:[NSNumber numberWithInt:self.windSpeedUnit] forKey:KEY_WIND_SPEED_UNIT];

    [self.unitButton setTitle:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit] forState:UIControlStateNormal];
    [self updateLabelsFromCurrentValues];

    if (self.graphView) {
        [self.graphView changeWindSpeedUnit:self.windSpeedUnit];
    }
}

/**** FACEBOOK SHARING ****/

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
    return self.currentLatitude;
}

- (NSNumber*) shareLongitude {
    return self.currentLongitude;
}

- (NSString*) shareUnit {
    return [UnitUtil englishDisplayNameForWindSpeedUnit:self.windSpeedUnit];
}

@end
