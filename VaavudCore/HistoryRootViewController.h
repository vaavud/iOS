//
//  HistoryRootViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 07/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RegisterNavigationController.h"

@protocol HistoryLoadedListener <NSObject>
- (void) historyLoaded;
@end

@interface HistoryRootViewController : UIViewController <RegisterNavigationControllerDelegate>

- (void) chooseContentControllerWithNoHistorySync;

@end
