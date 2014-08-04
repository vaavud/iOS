//
//  vaavudViewController.m
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "vaavudViewController.h"
#import "vaavudGraphHostingView.h"
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
#import <math.h>
#import <FacebookSDK/FacebookSDK.h>

@interface vaavudViewController ()

@property (nonatomic, weak) IBOutlet UILabel *averageHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel *currentHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel *unitHeadingLabel;

@property (nonatomic, weak) IBOutlet UILabel *actualLabel;
@property (nonatomic, weak) IBOutlet UILabel *averageLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxLabel;
@property (nonatomic, weak) IBOutlet UILabel *informationTextLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *statusBar;

@property (nonatomic, weak) IBOutlet UIButton *startStopButton;
@property (nonatomic) BOOL buttonShowsStart;
@property (nonatomic, strong) IBOutlet vaavudGraphHostingView *graphHostView;

@property (nonatomic, weak) IBOutlet UIButton *unitButton;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomLayoutGuideConstraint;

@property (nonatomic, strong) NSTimer *TimerLabel;
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

@implementation vaavudViewController {
    
}

- (void) viewDidLoad {
    [super viewDidLoad];

    self.windSpeedUnit = -1; // make sure windSpeedUnit is updated in viewWillAppear by setting it to an invalid value
    
    self.averageHeadingLabel.text = [NSLocalizedString(@"HEADING_AVERAGE", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.currentHeadingLabel.text = [NSLocalizedString(@"HEADING_CURRENT", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.maxHeadingLabel.text = [NSLocalizedString(@"HEADING_MAX", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.unitHeadingLabel.text = [NSLocalizedString(@"HEADING_UNIT", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    
    [self.graphHostView setupCorePlotGraph];
    
    self.compassTableShort = [NSArray arrayWithObjects:  @"N",@"NE",@"E",@"SE",@"S",@"SW",@"W",@"NW", nil];

    // Set correct font text colors
    UIColor *vaavudBlueUIcolor = [UIColor vaavudBlueColor];
    self.actualLabel.textColor = vaavudBlueUIcolor;
    self.maxLabel.textColor = vaavudBlueUIcolor;
    [self.unitButton setTitleColor:vaavudBlueUIcolor forState:UIControlStateNormal];
    
    self.buttonShowsStart = YES;
    [self.startStopButton setTitle:NSLocalizedString(@"BUTTON_START", nil) forState:UIControlStateNormal];
    self.startStopButton.backgroundColor = vaavudBlueUIcolor;
    self.startStopButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.startStopButton.layer.masksToBounds = YES;

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]];
    
    UIImage *aboutImage = [UIImage imageNamed:@"SettingsIcon.png"];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        aboutImage = [aboutImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:aboutImage style:UIBarButtonItemStylePlain target:self action:@selector(aboutButtonPushed)];
    self.navigationItem.rightBarButtonItem = item;
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    WindSpeedUnit newWindSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    if (newWindSpeedUnit != self.windSpeedUnit) {
        self.windSpeedUnit = newWindSpeedUnit;
        [self.unitButton setTitle:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit] forState:UIControlStateNormal];
        [self updateLabelsFromCurrentValues];
        
        // note: for some reason the y-axis is not changed correctly the first time, so we call the following method twice
        [self.graphHostView changeWindSpeedUnit:self.windSpeedUnit];
        [self.graphHostView changeWindSpeedUnit:self.windSpeedUnit];
    }
    
    [self.graphHostView resumeUpdates];
    
    if (!self.buttonShowsStart) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    //NSLog(@"[VaavudViewController] topLayoutGuide=%f", self.topLayoutGuide.length);
    //NSLog(@"[VaavudViewController] bottomLayoutGuide=%f", self.bottomLayoutGuide.length);

    // note: hack for content view underlapping tab view when clicking on another tab and back
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") && (self.bottomLayoutGuideConstraint != nil)) {
        //self.edgesForExtendedLayout = UIRectEdgeNone;
        
        //NSLog(@"[VaavudViewController] bottomLayoutGuide=%f", self.bottomLayoutGuide.length);
        
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

    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Measure Screen"];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.graphHostView pauseUpdates];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void) start {
    
    self.buttonShowsStart = NO;
    self.startStopButton.backgroundColor = [UIColor vaavudRedColor];
    [self.startStopButton setTitle:NSLocalizedString(@"BUTTON_STOP", nil) forState:UIControlStateNormal];

    // Setup graphView
    [self.statusBar setProgress:0];
    
    self.vaavudCoreController = [[VaavudCoreController alloc] init];
    self.vaavudCoreController.vaavudCoreControllerViewControllerDelegate = self; // set the core controller's view controller delegate to self (reports when meassurements are valid)
    
    self.graphHostView.vaavudCoreController = self.vaavudCoreController;
    
    self.actualLabelCurrentValue = nil;
    self.averageLabelCurrentValue = nil;
    self.maxLabelCurrentValue = nil;
    [self updateLabelsFromCurrentValues];
    
    [self.graphHostView setupCorePlotGraph];
    
    [self.vaavudCoreController start];
    self.TimerLabel = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(updateLabels) userInfo: nil repeats: YES];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (NSTimeInterval) stop:(BOOL)onlyUI {
    self.buttonShowsStart = YES;
    self.startStopButton.backgroundColor = [UIColor vaavudBlueColor];
    [self.startStopButton setTitle:NSLocalizedString(@"BUTTON_START", nil) forState:UIControlStateNormal];

    [self.displayLinkGraphUI invalidate];
    [self.displayLinkGraphValues invalidate];
    [self.TimerLabel invalidate];
    NSTimeInterval durationSeconds = 0.0;
    if (!onlyUI) {
        durationSeconds = [self.vaavudCoreController stop];
    }
    self.informationTextLabel.text = @"";
    
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
        [self.displayLinkGraphUI        invalidate];
        [self.displayLinkGraphValues    invalidate];
    }
    else {
        [self.graphHostView createNewPlot];
        
        self.displayLinkGraphUI = [CADisplayLink displayLinkWithTarget:self.graphHostView selector:@selector(shiftGraphX)];
        self.displayLinkGraphUI.frameInterval = 10; // SET VALUE HIGHER FOR IPHONE 4
        
        self.displayLinkGraphValues = [CADisplayLink displayLinkWithTarget:self.graphHostView selector:@selector(addDataPoint)];
        self.displayLinkGraphValues.frameInterval = 10; // SET VALUE HIGHER FOR IPHONE 4
        
        [self.displayLinkGraphUI        addToRunLoop:       [NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];
        [self.displayLinkGraphValues    addToRunLoop:       [NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];
    }
}

- (void) updateLabels {    
    
    if (self.isValid) {
        self.actualLabelCurrentValue = [self.vaavudCoreController.windSpeed lastObject];
        self.averageLabelCurrentValue = [self.vaavudCoreController getAverage];
        self.maxLabelCurrentValue = [self.vaavudCoreController getMax];
        
        self.informationTextLabel.text = NSLocalizedString(@"INFO_MEASURING", nil);
                
        [self.statusBar setProgress: [[self.vaavudCoreController getProgress] floatValue]];
        
    }
    else {
        self.actualLabelCurrentValue = nil;
        
        if (self.vaavudCoreController.dynamicsIsValid) {
            self.informationTextLabel.text = NSLocalizedString(@"INFO_NO_SIGNAL", nil);
        }
        else {
            self.informationTextLabel.text = NSLocalizedString(@"INFO_KEEP_STEADY", nil);
        }
    }

    [self updateLabelsFromCurrentValues];
}

- (void) updateLabelsFromCurrentValues {
    if (self.actualLabelCurrentValue != nil && !isnan([self.actualLabelCurrentValue doubleValue])) {
        self.actualLabel.text = [self formatValue:[UnitUtil displayWindSpeedFromDouble:[self.actualLabelCurrentValue doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        self.actualLabel.text = @"-";
    }
    
    if (self.averageLabelCurrentValue != nil && !isnan([self.averageLabelCurrentValue doubleValue])) {
        self.averageLabel.text = [self formatValue:[UnitUtil displayWindSpeedFromDouble:[self.averageLabelCurrentValue doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        self.averageLabel.text = @"-";
    }
    
    if (self.maxLabelCurrentValue != nil && !isnan([self.maxLabelCurrentValue doubleValue])) {
        self.maxLabel.text = [self formatValue:[UnitUtil displayWindSpeedFromDouble:[self.maxLabelCurrentValue doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        self.maxLabel.text = @"-";
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        self.vaavudCoreController.upsideDown = NO;
    }
    
    if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        self.vaavudCoreController.upsideDown = YES;
    }
}

- (IBAction) buttonPushed: (UIButton*) sender {
    if (self.buttonShowsStart) {
        [self start];
        
        if ([Property isMixpanelEnabled]) {
            NSNumber *measurementCount = [MeasurementSession MR_numberOfEntities];
            if (measurementCount) {
                [[Mixpanel sharedInstance] registerSuperProperties:@{@"Measurements": [measurementCount stringValue]}];
            }
            [[Mixpanel sharedInstance] track:@"Start Measurement"];

        }
    }
    else {
        NSTimeInterval durationSecounds = [self stop:NO];

        if ([Property isMixpanelEnabled]) {
            [[Mixpanel sharedInstance] track:@"Stop Measurement" properties:@{@"Duration": [NSNumber numberWithInt:round(durationSecounds)]}];
        }
        
        [self promptForFacebookSharing];
        [Property refreshHasWindMeter];
    }
}

- (IBAction) unitButtonPushed {
    self.windSpeedUnit = [UnitUtil nextWindSpeedUnit:self.windSpeedUnit];
    [Property setAsInteger:[NSNumber numberWithInt:self.windSpeedUnit] forKey:KEY_WIND_SPEED_UNIT];

    [self.unitButton setTitle:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit] forState:UIControlStateNormal];
    [self updateLabelsFromCurrentValues];

    // note: for some reason the y-axis is not changed correctly the first time, so we call the following method twice
    [self.graphHostView changeWindSpeedUnit:self.windSpeedUnit];
    [self.graphHostView changeWindSpeedUnit:self.windSpeedUnit];
}

- (void) aboutButtonPushed {
    [self performSegueWithIdentifier:@"settingsSegue" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void) promptForFacebookSharing {
    
    if (self.averageLabelCurrentValue && ([self.averageLabelCurrentValue floatValue] > 0.0F) && self.maxLabelCurrentValue && ([self.maxLabelCurrentValue floatValue] > 0.0F) && [ServerUploadManager sharedInstance].hasReachability && [Property getAsBoolean:KEY_ENABLE_SHARE_DIALOG defaultValue:YES]) {
        
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

- (void) shareSuccessful {
    [self dismissShareDialog];

    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Share Dialog Successful"];
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

- (NSNumber*) shareAvgSpeed {
    return self.averageLabelCurrentValue;
}

- (NSNumber*) shareMaxSpeed {
    return self.maxLabelCurrentValue;
}

- (NSNumber*) shareLatitude {
    return self.vaavudCoreController.currentLatitude;
}

- (NSNumber*) shareLongitude {
    return self.vaavudCoreController.currentLongitude;
}

@end
