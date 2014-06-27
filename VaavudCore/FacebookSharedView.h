//
//  FacebookSharedView.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 25/06/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "vaavudGraphHostingView.h"

@interface FacebookSharedView : UIView

@property (weak, nonatomic) IBOutlet UILabel *avgTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *avgValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *unitLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxValueLabel;
@property (weak, nonatomic) IBOutlet vaavudGraphHostingView *graphView;

@end
