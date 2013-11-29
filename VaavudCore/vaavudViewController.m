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
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import <math.h>

@interface vaavudViewController ()

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

@property (nonatomic, strong) UIImage *startButtonImage;
@property (nonatomic, strong) UIImage *stopButtonImage;

@property (nonatomic) BOOL isValid;

@property (nonatomic) WindSpeedUnit windSpeedUnit;

@property (nonatomic) NSNumber *actualLabelCurrentValue;
@property (nonatomic) NSNumber *averageLabelCurrentValue;
@property (nonatomic) NSNumber *maxLabelCurrentValue;

- (void) updateLabels;
- (void) start;
- (void) stop;

- (IBAction) buttonPushed: (id)sender;
- (IBAction) unitButtonPushed;

@end

@implementation vaavudViewController {
    
}

- (void) viewDidLoad {
    [super viewDidLoad];

    self.screenName = @"Measure Screen";
    self.windSpeedUnit = -1; // make sure windSpeedUnit is updated in viewWillAppear by setting it to an invalid value

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        UIImage *selectedTabImage = [[UIImage imageNamed:@"measure_selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.tabBarItem.selectedImage = selectedTabImage;
    }
    
    [self.graphHostView setupCorePlotGraph];
    
    self.compassTableShort = [NSArray arrayWithObjects:  @"N",@"NE",@"E",@"SE",@"S",@"SW",@"W",@"NW", nil];

    // Set correct font text colors
    UIColor *vaavudBlueUIcolor = [UIColor colorWithRed:(0/255.0) green:(174/255.0) blue:(239/255.0) alpha:1];
    self.actualLabel.textColor = vaavudBlueUIcolor;
    self.maxLabel.textColor = vaavudBlueUIcolor;
    [self.unitButton setTitleColor:vaavudBlueUIcolor forState:UIControlStateNormal];
    
    self.startButtonImage = [UIImage imageNamed: @"startButton.png"];
    self.stopButtonImage = [UIImage imageNamed: @"stopButton.png"];
    self.buttonShowsStart = YES;
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)viewWillAppear:(BOOL)animated {
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
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.graphHostView pauseUpdates];
}

- (void) start {
    
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
}

- (void) stop {
    [self.displayLinkGraphUI invalidate];
    [self.displayLinkGraphValues invalidate];
    [self.TimerLabel invalidate];
    [self.vaavudCoreController stop];
    self.informationTextLabel.text = @"";
}

- (void) windSpeedMeasurementsAreValid: (BOOL) valid {
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
        
        self.informationTextLabel.text = @"Measurement in progress";
                
        [self.statusBar setProgress: [[self.vaavudCoreController getProgress] floatValue]];
        
    }
    else {
        self.actualLabelCurrentValue = nil;
        
        if (self.vaavudCoreController.dynamicsIsValid) {
            self.informationTextLabel.text = @"No signal";
        }
        else {
            self.informationTextLabel.text = @"Keep vertical & steady";
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
        self.buttonShowsStart = NO;
        [self.startStopButton setBackgroundImage: self.stopButtonImage forState:UIControlStateNormal];
        [self start];
        
        [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"start button" label:nil value:nil] build]];
    }
    else {
        self.buttonShowsStart = YES;
        [self.startStopButton setBackgroundImage: self.startButtonImage forState:UIControlStateNormal];
        [self stop];

        [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"stop button" label:nil value:nil] build]];
    }
}

- (IBAction) unitButtonPushed {
    self.windSpeedUnit = [UnitUtil nextWindSpeedUnit:self.windSpeedUnit];
    [Property setAsInteger:[NSNumber numberWithInt:self.windSpeedUnit] forKey:KEY_WIND_SPEED_UNIT];

    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"unit button" label:[[NSNumber numberWithInt:self.windSpeedUnit] stringValue] value:nil] build]];

    [self.unitButton setTitle:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit] forState:UIControlStateNormal];
    [self updateLabelsFromCurrentValues];

    // note: for some reason the y-axis is not changed correctly the first time, so we call the following method twice
    [self.graphHostView changeWindSpeedUnit:self.windSpeedUnit];
    [self.graphHostView changeWindSpeedUnit:self.windSpeedUnit];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
