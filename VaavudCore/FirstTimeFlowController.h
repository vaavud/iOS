//
//  FirstTimeFlowController.h
//  Feast
//
//  Created by Thomas Stilling Ambus on 17/04/2014.
//  Copyright (c) 2014 Thomas Stilling Ambus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RegisterNavigationController.h"
#import "FirstTimeExplanationViewController.h"

@interface FirstTimeFlowController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, RegisterNavigationControllerDelegate, FirstTimeExplanationViewControllerDelegate>

@property (strong, nonatomic) NSArray *pageImages;
@property (strong, nonatomic) NSArray *pageTexts;
@property (strong, nonatomic) NSArray *pageMixpanelScreens;
@property (strong, nonatomic) NSArray *pageIds;

@end
