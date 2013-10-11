//
//  MeasurementTableViewCell.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 27/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "MeasurementTableViewCell.h"
#import "FormatUtil.h"

@implementation MeasurementTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void) setValues:(double)avgWindSpeed unit:(WindSpeedUnit)unit time:(NSDate*)time {
    
    if (!isnan(avgWindSpeed)) {
        self.avgWindSpeedLabel.text = [FormatUtil formatValueWithThreeDigits:[UnitUtil displayWindSpeedFromDouble:avgWindSpeed unit:unit]];
    }
    else {
        self.avgWindSpeedLabel.text = @"-";
    }

    NSString *unitName = [UnitUtil displayNameForWindSpeedUnit:unit];
    self.avgWindSpeedUnitLabel.text = unitName;
    
    self.timeLabel.text = [FormatUtil formatRelativeDate:time];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
