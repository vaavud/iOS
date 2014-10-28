//
//  AgriSummaryViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 28/10/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MeasurementSession+Util.h"

@interface AgriSummaryViewController : UIViewController <MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) MeasurementSession *measurementSession;

@end
