//
//  MeasureViewController.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VaavudCoreController.h"
#import "CorePlot-CocoaTouch.h"
#import "ShareDialog.h"
#import "SleipnirMeasurementController.h"

@interface MeasureViewController : UIViewController <VaavudCoreViewControllerDelegate, UIAlertViewDelegate, ShareDialogDelegate, SleipnirMeasurementControllerViewDelegate>

@property (nonatomic) BOOL lookupTemperature;
@property (nonatomic) BOOL shareToFacebook;

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

- (UILabel*) temperatureHeadingLabel;
- (UILabel*) temperatureLabel;

- (UILabel*) informationTextLabel;
- (UIProgressView*) statusBar;

- (UIButton*) startStopButton;

- (UIView*) graphContainer;

- (IBAction) startStopButtonPushed:(id)sender;
- (IBAction) unitButtonPushed:(id)sender;

@end
