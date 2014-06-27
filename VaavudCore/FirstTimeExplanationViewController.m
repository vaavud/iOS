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

@interface FirstTimeExplanationViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *explanationTextTopSpacingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightButtonHorizontalCenterConstraint;

@end

@implementation FirstTimeExplanationViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    UIImage *image = [UIImage imageNamed:self.imageName];
    self.imageView.image = image;    
    self.explanationLabel.text = self.explanationText;
    
    if (self.textVerticalMiddle) {
        self.explanationTextTopSpacingConstraint.constant = 420.0;
    }
    else {
        self.explanationTextTopSpacingConstraint.constant = 50.0;
    }
    
    [self.leftButton setTitle:NSLocalizedString(@"INTRO_BUTTON_BUY_WINDMETER", nil) forState:UIControlStateNormal];
    [self.rightButton setTitle:NSLocalizedString(@"INTRO_BUTTON_GOT_WINDMETER", nil) forState:UIControlStateNormal];
    self.leftButton.hidden = !self.showQuestionButtons;
    self.rightButton.hidden = !self.showQuestionButtons;

    if (self.showFinishButton) {
        self.rightButton.hidden = NO;
        self.rightButtonHorizontalCenterConstraint.constant = 0;
        [self.rightButton setTitle:NSLocalizedString(@"INTRO_BUTTON_FINISHED", nil) forState:UIControlStateNormal];
        self.explanationTextTopSpacingConstraint.constant = 360.0;
    }
    
    self.leftButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.leftButton.layer.masksToBounds = YES;
    self.rightButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.rightButton.layer.masksToBounds = YES;

}

- (IBAction)leftButtonPushed:(id)sender {
    NSString *country = [Property getAsString:KEY_COUNTRY];
    NSString *language = [Property getAsString:KEY_LANGUAGE];
    NSString *url = [NSString stringWithFormat:@"http://vaavud.com/mobile-shop-redirect/?country=%@&language=%@", country, language];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (IBAction)rightButtonPushed:(id)sender {
    
    if (self.showQuestionButtons) {
        FirstTimeExplanationViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTimeExplanationViewController"];
        
        viewController.imageName = @"FirstTime-4.jpg";
        viewController.explanationText = @"To take a proper wind measurement, plug in the wind meter and hold it up against the wind, facing the display towards yourself.";
        viewController.showQuestionButtons = NO;
        viewController.showFinishButton = YES;
        viewController.textVerticalMiddle = NO;
        
        viewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:viewController animated:YES completion:nil];
    }
    else if (self.showFinishButton) {
        UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TabBarController"];
        [UIApplication sharedApplication].delegate.window.rootViewController = viewController;
    }
}

@end
