//
//  MeasurementTableViewCell.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 27/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UnitUtil.h"

@interface MeasurementTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *avgWindSpeedLabel;
@property (nonatomic, weak) IBOutlet UILabel *avgWindSpeedUnitLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;

-(void) setValues:(double)avgWindSpeed unit:(WindSpeedUnit)unit time:(NSDate*)time;

@end
