//
//  SleipnirCalibrationViewController.m
//  Vaavud
//
//  Created by Andreas Okholm on 17/12/14.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "SleipnirCalibrationViewController.h"


@interface SleipnirCalibrationViewController ()

@end

@implementation SleipnirCalibrationViewController

- (void)viewDidLoad {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        //only apply the blur if the user hasn't disabled transparency effects
        if (!UIAccessibilityIsReduceTransparencyEnabled()) {
            
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
//            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];

            UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect: blurEffect];

            blurEffectView.frame = self.view.bounds;
            
            [self.view addSubview:blurEffectView];
            [self.view sendSubviewToBack:blurEffectView];
            
            self.view.backgroundColor = [UIColor clearColor];
            
            //        view.insertSubview(blurEffectView)
            //if you have more UIViews on screen, use insertSubview:belowSubview: to place it underneath the lowest view
            
            //add auto layout constraints so that the blur fills the screen upon rotating device
            //        blurEffectView.setTranslatesAutoresizingMaskIntoConstraints(false)
            //        view.addConstraint(NSLayoutConstraint(item: blurEffectView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
            //        view.addConstraint(NSLayoutConstraint(item: blurEffectView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
            //        view.addConstraint(NSLayoutConstraint(item: blurEffectView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
            //        view.addConstraint(NSLayoutConstraint(item: blurEffectView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))
        }
    }
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}



@end
