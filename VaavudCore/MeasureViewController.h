//
//  MeasureViewController.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "ShareDialog.h"
#import "WindMeasurementController.h"
#import "MeasurementSession+Util.h"

@interface MeasureViewController : UIViewController <UIAlertViewDelegate, ShareDialogDelegate, WindMeasurementControllerDelegate>

@property (nonatomic) BOOL shareToFacebook;
@property (nonatomic) BOOL buttonShowsStart;
@property (nonatomic) BOOL isMinimumThresholdReached;

- (UILabel*) averageHeadingLabel;
- (UILabel*) averageLabel;

- (UILabel*) currentHeadingLabel;
- (UILabel*) actualLabel;

- (UILabel*) maxHeadingLabel;
- (UILabel*) maxLabel;

- (UILabel*) unitHeadingLabel;
- (UIButton*) unitButton;

- (UILabel*) directionHeadingLabel;
- (UILabel*) directionLabel;
- (UIImageView*) directionImageView;

- (UILabel*) temperatureHeadingLabel;
- (UILabel*) temperatureLabel;

- (UILabel*) informationTextLabel;
- (UIProgressView*) statusBar;

- (UIButton*) startStopButton;

- (UIView*) graphContainer;

- (NSString*) stopButtonTitle;

- (IBAction) startStopButtonPushed:(id)sender;
- (IBAction) unitButtonPushed:(id)sender;

- (void) start;
- (void) stop;

- (void) measurementStarted;
- (void) measurementStopped:(MeasurementSession*)measurementSession;

- (void) minimumThresholdReached;

- (void) showNotification:(NSString*)title message:(NSString*)message dismissAfter:(NSTimeInterval)time;
- (void) dismissNotification;

@end
