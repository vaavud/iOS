//
//  MeasureViewController.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VaavudCoreController.h"
#import "vaavudGraphHostingView.h"
#import "CorePlot-CocoaTouch.h"
#import "ShareDialog.h"
#import <VaavudElectronicSDK/VEVaavudElectronicSDK.h>

@interface MeasureViewController : UIViewController <VaavudCoreViewControllerDelegate, UIAlertViewDelegate, ShareDialogDelegate, VaavudElectronicWindDelegate>

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

- (UILabel*) temperatureHeadingLabel;
- (UILabel*) temperatureLabel;

- (UILabel*) informationTextLabel;
- (UIProgressView*) statusBar;

- (UIButton*) startStopButton;

- (vaavudGraphHostingView*) graphHostView;

- (IBAction) startStopButtonPushed:(id)sender;
- (IBAction) unitButtonPushed:(id)sender;

@end
