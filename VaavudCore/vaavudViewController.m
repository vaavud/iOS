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

@interface vaavudViewController ()

@property (nonatomic, weak) IBOutlet UILabel *actualLabel;
@property (nonatomic, weak) IBOutlet UILabel *averageLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxLabel;
@property (nonatomic, weak) IBOutlet UILabel *unitLabel;
@property (nonatomic, weak) IBOutlet UILabel *informationTextLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *statusBar;

@property (nonatomic, weak) IBOutlet UIButton *startStopButton;
@property (nonatomic, strong) IBOutlet vaavudGraphHostingView *graphHostView;


@property (nonatomic, strong) NSTimer *TimerLabel;
@property (nonatomic, strong) CADisplayLink *displayLinkGraphUI;
@property (nonatomic, strong) CADisplayLink *displayLinkGraphValues;
@property (nonatomic, strong) VaavudCoreController *vaavudCoreController;
@property (nonatomic, strong) NSArray *compassTableShort;

@property (nonatomic, strong) UIImage *startButtonImage;
@property (nonatomic, strong) UIImage *stopButtonImage;

@property (nonatomic)           BOOL isValid;

@property (nonatomic) WindSpeedUnit windSpeedUnit;

- (void) updateLabels;
- (void) start;
- (void) stop;

- (IBAction) buttonPushed: (id)sender;

@end

@implementation vaavudViewController {
    
}



- (void)viewDidLoad  // FIRST METHOD CALLED (WHEN VIEW IS LOADED)
{
    [super viewDidLoad];
    
    [self.graphHostView setupCorePlotGraph];
    
    self.compassTableShort = [NSArray arrayWithObjects:  @"N",@"NE",@"E",@"SE",@"S",@"SW",@"W",@"NW", nil];
    

    // Set correct font text colors
    UIColor *vaavudBlueUIcolor = [UIColor colorWithRed:(0/255.0) green:(174/255.0) blue:(239/255.0) alpha:1];
    self.actualLabel.textColor = vaavudBlueUIcolor;
    self.maxLabel.textColor = vaavudBlueUIcolor;
    self.unitLabel.textColor = vaavudBlueUIcolor;
    
    self.windSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    self.unitLabel.attributedText = [[NSAttributedString alloc] initWithString:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit]];
    
    
    self.startButtonImage   = [UIImage imageNamed: @"startButton.png"];
    self.stopButtonImage    = [UIImage imageNamed: @"stopButton.png"];
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.vaavudCoreController stop];
}



- (void) start {
    
    // Setup graphView
    [self.statusBar setProgress:0];
    
    self.vaavudCoreController = [[VaavudCoreController alloc] init];
    self.vaavudCoreController.vaavudCoreControllerViewControllerDelegate = self; // set the core controller's view controller delegate to self (reports when meassurements are valid)
    
    self.graphHostView.vaavudCoreController = self.vaavudCoreController;
    
    [self.graphHostView setupCorePlotGraph];
    
    [self.vaavudCoreController start];
    self.TimerLabel         = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(updateLabels) userInfo: nil repeats: YES];
}


- (void) stop {

    [self.displayLinkGraphUI invalidate];
    [self.displayLinkGraphValues invalidate];
    [self.TimerLabel invalidate];
    [self.vaavudCoreController stop];
}


- (void) windSpeedMeasurementsAreValid: (BOOL) valid
{
    self.isValid = valid;
    
    if (!valid) {
        [self.displayLinkGraphUI        invalidate];
        [self.displayLinkGraphValues    invalidate];

    } else {
        [self.graphHostView createNewPlot];
        
        self.displayLinkGraphUI = [CADisplayLink displayLinkWithTarget:self.graphHostView selector:@selector(shiftGraphX)];
        self.displayLinkGraphUI.frameInterval = 10; // SET VALUE HIGHER FOR IPHONE 4
        
        self.displayLinkGraphValues = [CADisplayLink displayLinkWithTarget:self.graphHostView selector:@selector(addDataPoint)];
        self.displayLinkGraphValues.frameInterval = 10; // SET VALUE HIGHER FOR IPHONE 4
        
        [self.displayLinkGraphUI        addToRunLoop:       [NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];
        [self.displayLinkGraphValues    addToRunLoop:       [NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];

    }
    
}


- (void) updateLabels
{    
    
    if (self.isValid) {
        NSNumber *latestWindSpeed = [self.vaavudCoreController.windSpeed lastObject];
        self.actualLabel.text = [NSString stringWithFormat: @"%.1f", [UnitUtil toDisplayWindSpeed:[latestWindSpeed doubleValue] unit:self.windSpeedUnit]];
        self.averageLabel.text = [NSString stringWithFormat: @"%.1f", [UnitUtil toDisplayWindSpeed:[[self.vaavudCoreController getAverage] doubleValue] unit:self.windSpeedUnit]];
        self.maxLabel.text = [NSString stringWithFormat: @"%.1f", [UnitUtil toDisplayWindSpeed:[[self.vaavudCoreController getMax] doubleValue] unit:self.windSpeedUnit]];
        
        self.informationTextLabel.text = @"Measurement in progress";
        
        
        [self.statusBar setProgress: [[self.vaavudCoreController getProgress] floatValue]];
        
    } else {
        self.actualLabel.text = @"-";
        
        if (self.vaavudCoreController.dynamicsIsValid)
            self.informationTextLabel.text = @"No signal";
        else
            self.informationTextLabel.text = @"Keep vertical & steady";

    }

}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
        self.vaavudCoreController.upsideDown = NO;
    
    if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        self.vaavudCoreController.upsideDown = YES;
}


- (IBAction) buttonPushed: (UIButton*) sender
{
    
    NSString *buttonText = [NSString stringWithString: sender.currentTitle];
    
    if ([buttonText caseInsensitiveCompare: @"start"] == NSOrderedSame){
        [self.startStopButton setTitle: @"stop" forState:UIControlStateNormal];
        [self.startStopButton setImage: self.stopButtonImage forState:UIControlStateNormal];
        
        [self start];
    }
    
    if ([buttonText caseInsensitiveCompare: @"stop"] == NSOrderedSame){
        [self.startStopButton setTitle: @"start" forState:UIControlStateNormal];
        [self.startStopButton setImage: self.startButtonImage forState:UIControlStateNormal];

        [self stop];
    }
        

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

@end
