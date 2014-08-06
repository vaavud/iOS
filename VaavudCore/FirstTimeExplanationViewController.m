//
//  FirstTimeExplanationViewController.m
//  Feast
//
//  Created by Thomas Stilling Ambus on 17/04/2014.
//  Copyright (c) 2014 Thomas Stilling Ambus. All rights reserved.
//

#import "FirstTimeExplanationViewController.h"
#import "ImageUtil.h"
#import "Property+Util.h"
#import "UIColor+VaavudColors.h"
#import "Mixpanel.h"

@interface FirstTimeExplanationViewController ()

@property (nonatomic) BOOL hasClickedBuy;

@end

@implementation FirstTimeExplanationViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.hasClickedBuy = NO;
    
    UIImage *image = [UIImage imageNamed:self.imageName];
    self.imageView.image = image;
    self.topExplanationLabel.text = self.topExplanationText;
    self.explanationLabel.text = self.explanationText;
    
    if (self.topButtonText) {
        [self.topButton setTitle:self.topButtonText forState:UIControlStateNormal];
    }
    else {
        self.topButton.hidden = YES;
    }
    
    if (self.bottomButtonText) {
        [self.bottomButton setTitle:self.bottomButtonText forState:UIControlStateNormal];
        
        if (self.bottomButtonIsTransparent) {
            self.bottomButton.backgroundColor = [UIColor clearColor];
            self.bottomButton.titleLabel.textColor = [UIColor whiteColor];
        }
    }
    else {
        self.bottomButton.hidden = YES;
    }
    
    if (self.tinyButtonText) {
        [self.tinyButton setTitle:self.tinyButtonText forState:UIControlStateNormal];

        if (self.tinyButtonIsSolid) {
            self.tinyButton.titleLabel.font = [UIFont systemFontOfSize:18.0];
            self.tinyButton.titleLabel.textColor = [UIColor vaavudBlueColor];
            self.tinyButton.backgroundColor = [UIColor whiteColor];
        }
        else {
            self.tinyButton.backgroundColor = [UIColor clearColor];
        }
    }
    else {
        self.tinyButton.hidden = YES;
        self.explanationLabelBottomSpaceConstraint.constant = 50.0;
    }
    
    self.topButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.topButton.layer.masksToBounds = YES;
    self.bottomButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.bottomButton.layer.masksToBounds = YES;
    self.tinyButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.tinyButton.layer.masksToBounds = YES;

    if (self.pageId == 4) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
}

- (void) appDidBecomeActive:(NSNotification*) notification {
    //NSLog(@"appDidBecomeActive, hasClickedBuy=%@, currentPageId=%u", self.hasClickedBuy ? @"YES" : @"NO", self.pageId);
    if (self.hasClickedBuy && self.pageId == 4) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        if (self.delegate) {
            [self.delegate continueFlowFromController:self];
        }
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:self.mixpanelScreen];
    }
}

- (IBAction)topButtonPushed:(id)sender {
    
    if (self.delegate) {
        [self.delegate topButtonPushedOnController:self];
    }
    
    if (self.pageId == 4) {
        self.hasClickedBuy = YES;
    }
}

- (IBAction)bottomButtonPushed:(id)sender {

    if (self.delegate) {
        [self.delegate bottomButtonPushedOnController:self];
    }
}

- (IBAction)tinyButtonPushed:(id)sender {

    if (self.delegate) {
        [self.delegate tinyButtonPushedOnController:self];
    }
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
