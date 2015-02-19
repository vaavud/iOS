//
//  ParentViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 08/07/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ParentViewControllerDelegate <NSObject>

- (void)selectViewController;

@end

@interface ParentViewController : UIViewController

@property (nonatomic, weak) id<ParentViewControllerDelegate> delegate;

- (void)switchChildController:(UIViewController *)childViewController;

@end
