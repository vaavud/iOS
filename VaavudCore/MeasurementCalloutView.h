//
//  MeasurementCalloutView.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 30/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MeasurementAnnotation.h"
#import "MapViewController.h"

#define ROW_HEIGHT 40.0

@interface MeasurementCalloutView : UIView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIButton *mapButton;
@property (nonatomic, weak) IBOutlet UILabel *avgLabel;
@property (nonatomic, weak) IBOutlet UILabel *avgUnitLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxHeadingLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxUnitLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *nearbyHeadingLabel;
@property (nonatomic) WindSpeedUnit windSpeedUnit;
@property (nonatomic) MeasurementAnnotation *measurementAnnotation;
@property (nonatomic) MapViewController *mapViewController;
@property (nonatomic) NSArray *nearbyAnnotations;

@end
