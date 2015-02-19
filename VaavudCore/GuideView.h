//
//  GuideView.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 04/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GuideView : UIView

@property (weak, nonatomic) IBOutlet UILabel *headingLabel;
@property (weak, nonatomic) IBOutlet UILabel *explanationLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headingLabelWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *explanationLabelWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headingLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *explanationLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *labelVerticalSpaceConstraint;

- (CGFloat)preferredHeight;

@end
