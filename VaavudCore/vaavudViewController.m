//
//  vaavudViewController.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "vaavudViewController.h"
#import "VaavudCoreController.h"
#import "vaavudGraphHostingView.h"

@interface vaavudViewController ()

@property (nonatomic, weak) IBOutlet UILabel *actualLabel;
@property (nonatomic, weak) IBOutlet UILabel *averageLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxLabel;
@property (nonatomic, weak) IBOutlet UILabel *unitLabel;
@property (nonatomic, weak) IBOutlet UILabel *informationTextLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *statusBar;

@property (nonatomic, strong) IBOutlet UIButton *startStopButton;

@property (nonatomic, strong)   IBOutlet vaavudGraphHostingView *graphHostView;

@property (nonatomic, strong) VaavudCoreController *vaavudCoreController;

@property (nonatomic, strong) NSTimer *TimerLabel;
@property (nonatomic, strong) NSTimer *TimerGraphUI;
@property (nonatomic, strong) NSTimer *TimerGraphValues;

- (void) updateLabels;
- (void) start;
- (void) stop;

- (IBAction) buttonPushed: (id)sender;





@end

@implementation vaavudViewController {
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self.graphHostView setupCorePlotGraph];

    
//    self.actualLabel.font = [UIFont fontWithName:@"Arkitech-Medium" size:40];
    UIColor *vaavudBlueUIcolor = [UIColor colorWithRed:(0/255.0) green:(174/255.0) blue:(239/255.0) alpha:1];
    self.actualLabel.textColor = vaavudBlueUIcolor;
    self.maxLabel.textColor = vaavudBlueUIcolor;
    self.unitLabel.textColor = vaavudBlueUIcolor;
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.vaavudCoreController stop];
}



- (void) start {
    
    self.vaavudCoreController = [[VaavudCoreController alloc] init];
    
    self.graphHostView.vaavudCoreController = self.vaavudCoreController;
    
    [self.graphHostView setupCorePlotGraph];
    
    self.TimerGraphUI       = [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self.graphHostView selector: @selector(updateGraphUI) userInfo: nil repeats: YES];
    self.TimerGraphValues   = [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self.graphHostView selector: @selector(updateGraphValues) userInfo: nil repeats: YES];
    self.TimerLabel         = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(updateLabels) userInfo: nil repeats: YES];
    [self.vaavudCoreController start];
    
    [self.statusBar setProgress:0];
}


- (void) stop {
    [self.TimerGraphUI invalidate];
    [self.TimerGraphValues invalidate];
    [self.TimerLabel invalidate];
    [self.vaavudCoreController stop];
}





- (void) updateLabels
{
    BOOL isValid = [[self.vaavudCoreController.isValid lastObject] boolValue];

    if (isValid) {
        NSNumber *latestWindSpeed = [self.vaavudCoreController.windSpeed lastObject];
        self.actualLabel.text = [NSString stringWithFormat: @"%.1f", [latestWindSpeed doubleValue]];
        self.averageLabel.text = [NSString stringWithFormat: @"%.1f", [[self.vaavudCoreController getAverage] floatValue]];
        self.maxLabel.text = [NSString stringWithFormat: @"%.1f", [[self.vaavudCoreController getMax] floatValue]];
        
        self.informationTextLabel.text = @"";
        
        [self.statusBar setProgress: [[self.vaavudCoreController getProgress] floatValue]];
        
    } else {
        self.actualLabel.text = @"-";
        
        if (self.vaavudCoreController.dynamicsIsValid)
            self.informationTextLabel.text = @"No signal";
        else
            self.informationTextLabel.text = @"Keep vertical & steady";

    }

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
