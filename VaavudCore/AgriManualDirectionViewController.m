//
//  AgriManualDirectionViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 03/10/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AgriManualDirectionViewController.h"
#import "UIColor+VaavudColors.h"
#import "LocationManager.h"
#import "Property+Util.h"
#import "UnitUtil.h"
#import "Mixpanel.h"

@interface AgriManualDirectionViewController ()

@property (weak, nonatomic) IBOutlet UILabel *explanationLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIImageView *directionImageView;
@property (weak, nonatomic) IBOutlet UILabel *directionLabel;
@property (nonatomic, strong) NSNumber *latestDirection;
@property (nonatomic) NSInteger directionUnit;
@property (nonatomic, strong) NSTimer *directionTimer;

@end

@implementation AgriManualDirectionViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.nextButton setTitle:NSLocalizedString(@"BUTTON_NEXT", nil) forState:UIControlStateNormal];
    self.nextButton.backgroundColor = [UIColor vaavudColor];
    self.nextButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.nextButton.layer.masksToBounds = YES;
    self.nextButton.layer.borderWidth = 0.5f;
    self.nextButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.navigationItem.title = NSLocalizedString(@"AGRI_MANUAL_DIRECTION", nil);
    self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"NAVIGATION_BACK", nil);
    
    self.explanationLabel.text = NSLocalizedString(@"AGRI_MANUAL_DIRECTION_EXPLANATION", nil);
    
    self.latestDirection = nil;
    [self updateDirection];
    
    self.directionTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateDirection) userInfo:nil repeats:YES];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSNumber *directionUnitNumber = [Property getAsInteger:KEY_DIRECTION_UNIT];
    NSInteger directionUnit = (directionUnitNumber) ? [directionUnitNumber doubleValue] : 0;
    if (self.directionUnit != directionUnit) {
        self.directionUnit = directionUnit;
        [self updateDirection];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Agri Manual Direction Screen"];
    }
}

- (void) updateDirection {
    
    self.latestDirection = [LocationManager sharedInstance].latestHeading;
    
    if (self.latestDirection && !isnan([self.latestDirection doubleValue])) {
        
        if (self.directionLabel) {
            if (self.directionUnit == 0) {
                self.directionLabel.text = [UnitUtil displayNameForDirection:self.latestDirection];
            }
            else {
                self.directionLabel.text = [NSString stringWithFormat:@"%@°", [NSNumber numberWithInt:(int)round([self.latestDirection doubleValue])]];
            }
        }
        
        if (self.directionImageView) {
            NSString *imageName = [UnitUtil imageNameForDirection:self.latestDirection];
            if (imageName) {
                self.directionImageView.image = [UIImage imageNamed:imageName];
                self.directionImageView.hidden = NO;
            }
            else {
                self.directionImageView.hidden = YES;
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

- (IBAction) nextButtonClicked:(id)sender {

    if (self.measurementSession) {
        
        if (self.latestDirection || AGRI_DEBUG_ALWAYS_ENABLE_NEXT) {
            self.measurementSession.windDirection = self.latestDirection;
            
            NSLog(@"[AgriManualDirectionViewController] Next with direction=%@", self.measurementSession.windDirection);
            [self performSegueWithIdentifier:@"resultSegue" sender:self];
        }
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UIViewController *controller = [segue destinationViewController];
    
    if ([controller conformsToProtocol:@protocol(MeasurementSessionConsumer)]) {
        UIViewController<MeasurementSessionConsumer> *consumer = (UIViewController<MeasurementSessionConsumer>*) controller;
        [consumer setMeasurementSession:self.measurementSession];
        [consumer setHasTemperature:self.hasTemperature];
        [consumer setHasDirection:self.hasDirection];
    }
}

@end
