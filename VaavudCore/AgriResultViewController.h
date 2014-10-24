//
//  AgriResultViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 02/10/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AgriMeasureViewController.h"

@interface AgriResultViewController : UIViewController <MeasurementSessionConsumer, UIAlertViewDelegate>

@property (nonatomic, strong) MeasurementSession *measurementSession;
@property (nonatomic) BOOL hasTemperature;
@property (nonatomic) BOOL hasDirection;

@end
