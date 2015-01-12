//
//  GuideView.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 04/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "GuideView.h"

@implementation GuideView

- (CGFloat)preferredHeight {
    CGFloat headingHeight = [self.headingLabel sizeThatFits:CGSizeMake(self.headingLabelWidthConstraint.constant, FLT_MAX)].height;
    CGFloat explanationHeight = [self.explanationLabel sizeThatFits:CGSizeMake(self.explanationLabelWidthConstraint.constant, FLT_MAX)].height;
    self.headingLabelHeightConstraint.constant = headingHeight;
    self.explanationLabelHeightConstraint.constant = explanationHeight;
    return self.topSpaceConstraint.constant + headingHeight + self.labelVerticalSpaceConstraint.constant + explanationHeight + self.topSpaceConstraint.constant + 10.0;
}

@end
