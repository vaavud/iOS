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
#import "SleipnirMeasurementController.h"
#import "ModelManager.h"
#import "Vaavud-Swift.h"

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

@property (nonatomic) BOOL hasShowsCalibrationScreen;


@property (nonatomic) float latestSpeed;
@property (nonatomic) float latestDirection;

@property (nonatomic) float currentSpeed;
@property (nonatomic) float averageSpeed;
@property (nonatomic) float maxSpeed;

@property (nonatomic) float currentDirection;

@end

@implementation CoreMeasureViewController

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (IBAction)debugDoublePanned:(UIPanGestureRecognizer *)sender {
    self.latestSpeed = MAX(0, self.latestSpeed - [sender translationInView:self.view].y/20);
    self.latestDirection = MIN(360, MAX(0, self.latestDirection + [sender translationInView:self.view].x/2));
    
    [sender setTranslation:CGPointZero inView:self.view];
}

-(void)update:(CADisplayLink *)link {
    float s = 0.05;
    
    self.currentSpeed = s*self.latestSpeed + (1 - s)*self.currentSpeed;
    float r = 0.01;
    self.averageSpeed = r*self.currentSpeed + (1 - r)*self.averageSpeed;
    self.maxSpeed = MAX(self.maxSpeed, self.currentSpeed);
    [self addSpeedMeasurement:@(self.currentSpeed) avgSpeed:@(self.averageSpeed) maxSpeed:@(self.maxSpeed)];
    
    self.currentDirection = s*self.latestDirection + (1 - s)*self.currentDirection;
    [self updateDirection:@(self.currentDirection)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.rotatingImageView = [[UIImageView alloc] initWithFrame:self.directionImageView.bounds];
    [self.directionImageView addSubview:self.rotatingImageView];
    
    [[CADisplayLink displayLinkWithTarget:self selector:@selector(update:)] addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)calibrateIfNeeded {
    BOOL sleipnir = [SleipnirMeasurementController sharedInstance].isDeviceConnected;
    
	if (sleipnir && !self.presentedViewController && !self.hasShowsCalibrationScreen && ![Property getAsBoolean:KEY_HAS_CALIBRATED]) {
        [self performSegueWithIdentifier:@"MandatoryCalibration" sender:self];
        self.hasShowsCalibrationScreen = YES;
    }
}

-(void)deviceConnected:(WindMeterDeviceType)device {
    [super deviceConnected:device];
    [self calibrateIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
        
    [self calibrateIfNeeded];
    //NSLog(@"[CoreMeasureViewController] topLayoutGuide=%f", self.topLayoutGuide.length);
    //NSLog(@"[CoreMeasureViewController] bottomLayoutGuide=%f", self.bottomLayoutGuide.length);
    
    // note: hack for content view underlapping tab view when clicking on another tab and back
    if (self.bottomLayoutGuideConstraint != nil) {
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SummaryFromMeasureSegue"]) {
        CoreSummaryViewController *destination = segue.destinationViewController;
        destination.session = self.concludedSession;
        self.concludedSession = nil;
    }
}

@end




