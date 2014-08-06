//
//  FirstTimeExplanationViewController.h
//  Feast
//
//  Created by Thomas Stilling Ambus on 17/04/2014.
//  Copyright (c) 2014 Thomas Stilling Ambus. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FirstTimeExplanationViewController;

@protocol FirstTimeExplanationViewControllerDelegate <NSObject>

- (void) topButtonPushedOnController:(FirstTimeExplanationViewController*)controller;
- (void) bottomButtonPushedOnController:(FirstTimeExplanationViewController*)controller;
- (void) tinyButtonPushedOnController:(FirstTimeExplanationViewController*)controller;
- (void) continueFlowFromController:(FirstTimeExplanationViewController*)controller;

@end

@interface FirstTimeExplanationViewController : UIViewController

@property (nonatomic, weak) id<FirstTimeExplanationViewControllerDelegate> delegate;

@property (nonatomic) NSString *imageName;
@property (nonatomic) NSString *topExplanationText;
@property (nonatomic) NSString *explanationText;
@property (nonatomic) NSString *topButtonText;
@property (nonatomic) NSString *bottomButtonText;
@property (nonatomic) NSString *tinyButtonText;
@property (nonatomic) BOOL bottomButtonIsTransparent;
@property (nonatomic) BOOL tinyButtonIsSolid;
@property (nonatomic) NSString *mixpanelScreen;
@property (nonatomic) NSUInteger pageIndex;
@property (nonatomic) NSUInteger pageId;

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *explanationLabel;
@property (weak, nonatomic) IBOutlet UILabel *topExplanationLabel;
@property (weak, nonatomic) IBOutlet UIButton *topButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;
@property (weak, nonatomic) IBOutlet UIButton *tinyButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *explanationLabelBottomSpaceConstraint;

@end
