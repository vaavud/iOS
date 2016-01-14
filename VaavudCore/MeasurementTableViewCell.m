//
//  MeasurementTableViewCell.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 27/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "MeasurementTableViewCell.h"
#import "FormatUtil.h"
#import "Vaavud-Swift.h"

@implementation MeasurementTableViewCell

-(void)setValues:(double)avgWindSpeed
            time:(NSDate *)time
   windDirection:(NSNumber *)direction {
    
    if (!isnan(avgWindSpeed)) {
        self.avgWindSpeedLabel.text = [[VaavudFormatter shared] localizedSpeed:avgWindSpeed digits:3];
    }
    else {
        self.avgWindSpeedLabel.text = @"-";
    }
    
    self.avgWindSpeedUnitLabel.text = [[VaavudFormatter shared] speedUnitLocalName];
    self.timeLabel.text = [FormatUtil formatRelativeDate:time];
    
    if (direction) {
        self.directionLabel.text = [[VaavudFormatter shared] localizedDirection:direction.floatValue];
        self.directionLabel.hidden = NO;
        self.directionImageView.image = [UIImage imageNamed:@"WindArrow"];
        self.directionImageView.transform = [VaavudFormatter transformWithDirection:direction.floatValue];
        self.directionImageView.hidden = NO;
    }
    else {
        self.directionImageView.hidden = YES;
        self.directionLabel.hidden = YES;
    }
}

@end
