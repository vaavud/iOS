//
//  FirstTimeExplanationViewController.h
//  Feast
//
//  Created by Thomas Stilling Ambus on 17/04/2014.
//  Copyright (c) 2014 Thomas Stilling Ambus. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstTimeExplanationViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *explanationLabel;

@property (nonatomic) BOOL textVerticalMiddle;
@property (nonatomic) BOOL showQuestionButtons;
@property (nonatomic) BOOL showFinishButton;
@property (nonatomic) NSString *imageName;
@property (nonatomic) NSString *explanationText;
@property (nonatomic) NSUInteger pageIndex;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@end
