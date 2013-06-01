//
//  vaavudViewController.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "vaavudViewController.h"
#import "vaavudGraphHostingView.h"

@interface vaavudViewController ()

@property (nonatomic, weak) IBOutlet UILabel *actualLabel;
@property (nonatomic, weak) IBOutlet UILabel *averageLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxLabel;
@property (nonatomic, weak) IBOutlet UILabel *unitLabel;
@property (nonatomic, weak) IBOutlet UILabel *windDirectionLabel;
@property (nonatomic, weak) IBOutlet UILabel *informationTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *windDirectionStatusLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *statusBar;

@property (nonatomic, weak) IBOutlet UIButton *startStopButton;
@property (nonatomic, weak) IBOutlet UIButton *windDirectionStatusButton;
@property (nonatomic, strong) IBOutlet vaavudGraphHostingView *graphHostView;


@property (nonatomic, strong) NSTimer *TimerLabel;
@property (nonatomic, strong) CADisplayLink *displayLinkGraphUI;
@property (nonatomic, strong) CADisplayLink *displayLinkGraphValues;
@property (nonatomic, strong) VaavudCoreController *vaavudCoreController;
@property (nonatomic, strong) NSArray *compassTableShort;

@property (nonatomic)           BOOL isValid;

- (void) updateLabels;
- (void) start;
- (void) stop;

- (IBAction) buttonPushed: (id)sender;
- (IBAction) windDirectionStatusToggle:(id)sender;


@end

@implementation vaavudViewController {
    
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.graphHostView setupCorePlotGraph];
    
    self.compassTableShort = [NSArray arrayWithObjects:  @"N",@"NE",@"E",@"SE",@"S",@"SW",@"W",@"NW", nil];
    
    self.windDirectionStatusLabel.lineBreakMode = NSLineBreakByCharWrapping;
    self.windDirectionStatusLabel.numberOfLines = 0;
    self.windDirectionStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.windDirectionStatusLabel.text          = @"CONFIRM\nDIRECTION";

    
//    self.actualLabel.font = [UIFont fontWithName:@"Arkitech-Medium" size:40];
    
    // Set correct font text colors
    UIColor *vaavudBlueUIcolor = [UIColor colorWithRed:(0/255.0) green:(174/255.0) blue:(239/255.0) alpha:1];
    self.actualLabel.textColor = vaavudBlueUIcolor;
    self.maxLabel.textColor = vaavudBlueUIcolor;
    self.unitLabel.textColor = vaavudBlueUIcolor;
    self.windDirectionLabel.textColor = vaavudBlueUIcolor;

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
        self.displayLinkGraphUI.frameInterval = 3; // SET VALUE HIGHER FOR IPHONE 4
        
        self.displayLinkGraphValues = [CADisplayLink displayLinkWithTarget:self.graphHostView selector:@selector(addDataPoint)];
        self.displayLinkGraphValues.frameInterval = 5; // SET VALUE HIGHER FOR IPHONE 4
        
        [self.displayLinkGraphUI        addToRunLoop:       [NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];
        [self.displayLinkGraphValues    addToRunLoop:       [NSRunLoop currentRunLoop] forMode:[[NSRunLoop currentRunLoop] currentMode]];

    }
    
}


- (void) updateLabels
{    
    
    if (self.isValid) {
        NSNumber *latestWindSpeed = [self.vaavudCoreController.windSpeed lastObject];
        self.actualLabel.text = [NSString stringWithFormat: @"%.1f", [latestWindSpeed doubleValue]];
        self.averageLabel.text = [NSString stringWithFormat: @"%.1f", [[self.vaavudCoreController getAverage] floatValue]];
        self.maxLabel.text = [NSString stringWithFormat: @"%.1f", [[self.vaavudCoreController getMax] floatValue]];
        
        self.informationTextLabel.text = @"";
        
        NSNumber *latestWindDicretion = self.vaavudCoreController.setWindDirection;
        
        
        if (latestWindDicretion)
        {
            
            NSString *compassText = self.compassTableShort[([latestWindDicretion integerValue]+360/8/2)%360/(360/8)];
            self.windDirectionLabel.text = [NSString stringWithFormat: @"%.0f%@", [latestWindDicretion doubleValue], compassText];
            self.windDirectionLabel.text = compassText;

        }
        
        
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
        [self start];
    }
    
    if ([buttonText caseInsensitiveCompare: @"stop"] == NSOrderedSame){
        [self.startStopButton setTitle: @"start" forState:UIControlStateNormal];
        [self stop];
    }
        

}

- (IBAction)windDirectionStatusToggle:(id)sender {
    
    if (self.vaavudCoreController.windDirectionIsConfirmed) {
        self.vaavudCoreController.windDirectionIsConfirmed = NO;
        self.windDirectionStatusLabel.text = @"CONFIRM\nDIRECTION";
    } else {
        self.vaavudCoreController.windDirectionIsConfirmed = YES;
        self.windDirectionStatusLabel.text = @"CONFIRMED\nDIRECTION";
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void) newWindSpeed: (float) speed
//{
//    self.mainWindSpeedLabel.text = [NSString stringWithFormat: @"%.1f", speed];
//}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

@end
