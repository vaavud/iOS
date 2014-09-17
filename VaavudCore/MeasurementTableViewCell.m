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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void) setValues:(double)avgWindSpeed unit:(WindSpeedUnit)unit time:(NSDate*)time windDirection:(NSNumber*)direction directionUnit:(NSInteger)directionUnit {
    
    if (!isnan(avgWindSpeed)) {
        self.avgWindSpeedLabel.text = [FormatUtil formatValueWithThreeDigits:[UnitUtil displayWindSpeedFromDouble:avgWindSpeed unit:unit]];
    }
    else {
        self.avgWindSpeedLabel.text = @"-";
    }

    NSString *unitName = [UnitUtil displayNameForWindSpeedUnit:unit];
    self.avgWindSpeedUnitLabel.text = unitName;
    
    self.timeLabel.text = [FormatUtil formatRelativeDate:time];
    
    if (direction) {
        
        if (directionUnit == 0) {
            self.directionLabel.text = [UnitUtil displayNameForDirection:direction];
        }
        else {
            self.directionLabel.text = [NSString stringWithFormat:@"%@°", [NSNumber numberWithInt:(int)round([direction doubleValue])]];
        }
        self.directionLabel.hidden = NO;
        
        NSString *imageName = [UnitUtil imageNameForDirection:direction];
        if (imageName) {
            self.directionImageView.image = [UIImage imageNamed:imageName];
            self.directionImageView.hidden = NO;
        }
        else {
            self.directionImageView.hidden = YES;
        }
    }
    else {
        self.directionImageView.hidden = YES;
        self.directionLabel.hidden = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
