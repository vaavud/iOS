//
//  AgriMeasureViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 25/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#define AGRI_DEBUG_ALWAYS_ENABLE_NEXT NO

#import <UIKit/UIKit.h>
#import "MeasureViewController.h"

@protocol MeasurementSessionConsumer <NSObject>
- (void) setMeasurementSession:(MeasurementSession*)session;
- (void) setHasTemperature:(BOOL)temperature;
- (void) setHasDirection:(BOOL)direction;
@end

@interface AgriMeasureViewController : MeasureViewController

@end
