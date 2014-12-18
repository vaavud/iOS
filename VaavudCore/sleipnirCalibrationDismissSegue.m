//
//  sleipnirCalibrationDismissSegue.m
//  Vaavud
//
//  Created by Andreas Okholm on 17/12/14.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "sleipnirCalibrationDismissSegue.h"

@implementation sleipnirCalibrationDismissSegue

- (void)perform {
    UIViewController *sourceViewController = self.sourceViewController;
    
    UIViewController *baseModalViewController = sourceViewController;
    
    while (baseModalViewController.presentingViewController != nil) {
        baseModalViewController = baseModalViewController.presentingViewController;
    }
    
    [baseModalViewController dismissViewControllerAnimated:YES completion:nil];
    
    
//    [sourceViewController.navigationController.presentingViewController  :YES completion:nil];
}

@end
