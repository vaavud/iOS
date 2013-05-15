//
//  vaavudViewController.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VaavudCoreController.h"

@interface vaavudViewController : UIViewController <VaavudCoreControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *mainWindSpeedLabel;

@end
