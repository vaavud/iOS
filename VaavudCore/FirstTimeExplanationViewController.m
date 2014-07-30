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

@end

@implementation FirstTimeExplanationViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
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
    }
    else {
        self.bottomButton.hidden = YES;
    }
    
    if (self.tinyButtonText) {
        [self.tinyButton setTitle:self.tinyButtonText forState:UIControlStateNormal];
    }
    else {
        self.tinyButton.hidden = YES;
    }
    
    self.topButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.topButton.layer.masksToBounds = YES;
    self.bottomButton.layer.cornerRadius = BUTTON_CORNER_RADIUS;
    self.bottomButton.layer.masksToBounds = YES;
}

- (IBAction)topButtonPushed:(id)sender {
    
    if (self.delegate) {
        [self.delegate topButtonPushedOnController:self];
    }
    
    /*
    NSString *country = [Property getAsString:KEY_COUNTRY];
    NSString *language = [Property getAsString:KEY_LANGUAGE];
    NSString *url = [NSString stringWithFormat:@"http://vaavud.com/mobile-shop-redirect/?country=%@&language=%@", country, language];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    */
}

- (IBAction)bottomButtonPushed:(id)sender {

    if (self.delegate) {
        [self.delegate bottomButtonPushedOnController:self];
    }

    /*
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
    */
}

- (IBAction)tinyButtonPushed:(id)sender {

    if (self.delegate) {
        [self.delegate tinyButtonPushedOnController:self];
    }
}

@end
