//
//  TabBarControllerViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 20/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMCalloutView.h"
#import "DismissOnTouchUIView.h"

#define CALLOUT_GUIDE_VIEW_WIDTH 250.0

@interface TabBarController : UITabBarController <SMCalloutViewDelegate,DismissOnTouchUIViewDelegate>

- (BOOL) isShowingGuideView;
- (void) showCalloutGuideView:(NSString*)headingText explanationText:(NSString*)explanationText customPosition:(CGRect)rect inView:(UIView*)inView;

@end
