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

@interface MeasureViewController : UIViewController <VaavudCoreViewControllerDelegate, UIAlertViewDelegate, ShareDialogDelegate>

- (UILabel*) averageHeadingLabel;
- (UILabel*) currentHeadingLabel;
- (UILabel*) maxHeadingLabel;
- (UILabel*) unitHeadingLabel;

- (UILabel*) actualLabel;
- (UILabel*) averageLabel;
- (UILabel*) maxLabel;
- (UILabel*) informationTextLabel;
- (UIProgressView*) statusBar;

- (UIButton*) startStopButton;
- (UIButton*) unitButton;

- (vaavudGraphHostingView*) graphHostView;

- (IBAction) startStopButtonPushed:(id)sender;
- (IBAction) unitButtonPushed:(id)sender;

@end
