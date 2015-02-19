//
//  AgriMeasureViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 25/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MeasureViewController.h"

@protocol MeasurementSessionConsumer
- (void)setMeasurementSession:(MeasurementSession *)session;
- (void)setHasTemperature:(BOOL)temperature;
- (void)setHasDirection:(BOOL)direction;
@end

@interface AgriMeasureViewController : MeasureViewController

@end
