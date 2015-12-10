//
//  TabBarControllerViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 20/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "TabBarController.h"
#import "Vaavud-Swift.h"
#import "UIColor+VaavudColors.h"
#import "CustomSMCalloutDrawnBackgroundView.h"
#import "GuideView.h"
#import "RegisterViewController.h"
#import "HistoryTableViewController.h"
#import "ServerUploadManager.h"
#import "AccountManager.h"
#import "RegisterNavigationController.h"
#import "UIImage+Vaavud.h"
#import "Property+Util.h"
#import <VaavudSDK/VaavudSDK-Swift.h>
#import "MapViewController.h"

@interface TabBarController ()<UITabBarControllerDelegate>

@property (nonatomic) GuideView *calloutGuideView;
@property (nonatomic) SMCalloutView *calloutView;
@property (nonatomic) DismissOnTouchUIView *overlayDimmingView;
@property (nonatomic) BOOL isCalloutGuideViewShown;
@property (nonatomic) UIButton *measureButton;
@property (nonatomic) CGFloat laidOutWidth;

@property (nonatomic) int sleipnirFromCallbackAttempts;

@property (nonatomic) VaavudInteractions *interactions;

@end

@implementation TabBarController



- (void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (![[AuthorizationController shared] verifyAuth]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        UIViewController *registration = [storyboard instantiateViewControllerWithIdentifier:@"NavigationLogin"];
        [self presentViewController:registration animated:YES completion:nil];
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.sleipnirFromCallbackAttempts = 0;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect frame = self.tabBar.bounds;
    frame.size.width = 70;
    button.frame = frame;
    button.layer.zPosition = 100;
    [button setImage:[UIImage imageNamed:@"MeasureButton"] forState:UIControlStateNormal];
    
    [self.tabBar addSubview:button];
    
    self.interactions = [VaavudInteractions new];
    self.measureButton = button;
    
    self.delegate = self;
    
    [self setSelectedIndex:1];
    
    self.tabBar.tintColor = [UIColor vaavudBlueColor];
    
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"GuideView" owner:self options:nil];
    self.calloutGuideView = [topLevelObjects objectAtIndex:0];
    self.calloutGuideView.frame = CGRectMake(0, 0, CALLOUT_GUIDE_VIEW_WIDTH, [self.calloutGuideView preferredHeight]);
    self.calloutGuideView.backgroundColor = [UIColor clearColor];
    self.calloutGuideView.headingLabel.textColor = [UIColor darkGrayColor];
    self.calloutGuideView.explanationLabel.textColor = [UIColor darkGrayColor];
    self.calloutGuideView.topSpaceConstraint.constant = 10.0;
    self.calloutGuideView.headingLabelWidthConstraint.constant = CALLOUT_GUIDE_VIEW_WIDTH - 20.0;
    self.calloutGuideView.explanationLabelWidthConstraint.constant = CALLOUT_GUIDE_VIEW_WIDTH - 20.0;
    self.calloutGuideView.labelVerticalSpaceConstraint.constant = 5.0;
    
    UITapGestureRecognizer *calloutGuideViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(guideViewTap:)];
    [self.calloutGuideView addGestureRecognizer:calloutGuideViewTapRecognizer];
    
    self.isCalloutGuideViewShown = NO;
    
    self.calloutView = [SMCalloutView new];
    self.calloutView.delegate = self;
    self.calloutView.presentAnimation = SMCalloutAnimationStretch;
    self.calloutView.translatesAutoresizingMaskIntoConstraints = YES;
    self.calloutView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    for (UITabBarItem *item in self.tabBar.items) {
        item.imageInsets = UIEdgeInsetsMake(6.0, 0.0, -6.0, 0.0);
    }
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillLayoutSubviews {
    CGFloat width = self.tabBar.bounds.size.width/self.tabBar.items.count;
    CGFloat height = self.tabBar.bounds.size.height;
    
    if (width == self.laidOutWidth) { return; }
    
    self.tabBar.selectionIndicatorImage = [UIImage imageWithColor:[UIColor vaavudTabbarSelectedColor] forSize:CGSizeMake(width, height)];
    
    CGRect frame = self.measureButton.frame;
    frame.origin.x = self.tabBar.bounds.size.width/2 - frame.size.width/2;
    self.measureButton.frame = frame;
    
    self.laidOutWidth = width;
}

- (void)takeMeasurementFromUrlScheme {
    [self takeMeasurement:YES];
}

- (void)takeMeasurement:(BOOL)fromUrlScheme {
    if ([Property getAsBoolean:KEY_USES_SLEIPNIR] && !VaavudSleipnirAvailability.available) {
        if (fromUrlScheme && self.sleipnirFromCallbackAttempts < 10) {
            self.sleipnirFromCallbackAttempts++;
            [self performSelector:@selector(takeMeasurementFromUrlScheme) withObject:nil afterDelay:0.1];
            return;
        }
        
        [self.interactions showLocalAlert:@"SLEIPNIR_PROBLEM_TITLE" messageKey:@"SLEIPNIR_PROBLEM_MESSAGE" cancelKey:@"BUTTON_OK" otherKey:@"SLEIPNIR_PROBLEM_SWITCH" action:^{
            [Property setAsBoolean:NO forKey:KEY_USES_SLEIPNIR];
            [[NSNotificationCenter defaultCenter] postNotificationName:KEY_WINDMETERMODEL_CHANGED object:self];
            [self performSegueWithIdentifier:@"ShowMeasureScreen" sender:self];
        } on:self];
    }
    else {
        [self performSegueWithIdentifier:@"ShowMeasureScreen" sender:self];
    }
    
    self.sleipnirFromCallbackAttempts = 0;
}

-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    // Measure button
    if (viewController == self.childViewControllers[2]) {
        [Property setAsBoolean:YES forKey:KEY_MAP_GUIDE_MEASURE_BUTTON_SHOWN];
        [self takeMeasurement:NO];
        return NO;
    }
    
//    // History screen
//    if (![AccountManager sharedInstance].isLoggedIn && viewController == self.childViewControllers[3]) {
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Register" bundle:nil];
//        RegisterViewController *registration = [storyboard instantiateViewControllerWithIdentifier:@"RegisterViewController"];
//        registration.teaserLabelText = NSLocalizedString(@"HISTORY_REGISTER_TEASER", nil);
//        registration.completion = ^{
//            NSLog(@"======= did login");
//            [[ServerUploadManager sharedInstance] syncHistory:2 ignoreGracePeriod:YES success:^{
//                NSLog(@"======= synced history after login");
//                
//            } failure:^(NSError *error) {
//                NSLog(@"======= FAILED synced history after login, %@", error);
//            }];
//            self.selectedIndex = 3;
//
//            [self dismissViewControllerAnimated:YES completion:^{
//                NSLog(@"=== login did dismiss");
//            }];
//        };
//        
//        RotatableNavigationController *nav = [RotatableNavigationController new];
//        nav.viewControllers = @[registration];
//        [self presentViewController:nav animated:YES completion:nil];
//        
//        return NO;
//    }
    
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)guideViewTap:(UITapGestureRecognizer *)recognizer {
    [self hideCalloutGuideView:YES];
}

- (void)dismissOverlayView {
    [self hideCalloutGuideView:YES];
}

- (BOOL)isShowingGuideView {
    return self.isCalloutGuideViewShown;
}

- (void)showCalloutGuideView:(NSString *)headingText
             explanationText:(NSString *)explanationText
              customPosition:(CGRect)rect
                   withArrow:(BOOL)withArrow
                      inView:(UIView *)inView {
    if (self.isCalloutGuideViewShown) {
        [self hideCalloutGuideView:NO];
    }
    
    self.calloutGuideView.headingLabel.text = headingText;
    self.calloutGuideView.explanationLabel.text = explanationText;
    
    CGFloat preferredHeight = [self.calloutGuideView preferredHeight];
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CALLOUT_GUIDE_VIEW_WIDTH, preferredHeight)];
    self.calloutGuideView.frame = CGRectMake(0, 0, CALLOUT_GUIDE_VIEW_WIDTH, preferredHeight);
    [containerView addSubview:self.calloutGuideView];
    
    self.calloutView.contentView = containerView;
    self.calloutView.backgroundView = withArrow ? [CustomSMCalloutDrawnBackgroundView view] : [CustomSMCalloutDrawnBackgroundView viewWithNoArrow];
    
    SMCalloutArrowDirection arrowDirection = SMCalloutArrowDirectionDown;
    arrowDirection = SMCalloutArrowDirectionAny;
    
    if (!inView) {
        inView = self.view;

        CGFloat overlayDimmingViewHeight = inView.bounds.size.height;
        CGRect overlayDimmingViewRect = CGRectMake(0, 0, inView.bounds.size.width, overlayDimmingViewHeight);
        
        self.overlayDimmingView = [[DismissOnTouchUIView alloc] initWithFrame:overlayDimmingViewRect];
        self.overlayDimmingView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.0];
        self.overlayDimmingView.translatesAutoresizingMaskIntoConstraints = YES;
        self.overlayDimmingView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [inView addSubview:self.overlayDimmingView];
        self.overlayDimmingView.delegate = self;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.overlayDimmingView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.3];
        } completion:nil];
    }
    
    [self.calloutView presentCalloutFromRect:rect
                                      inView:inView
                           constrainedToView:inView
                    permittedArrowDirections:arrowDirection
                                    animated:YES];
    
    self.isCalloutGuideViewShown = YES;
}

- (void)hideCalloutGuideView:(BOOL)animated {
    self.isCalloutGuideViewShown = NO;
    
    if (self.calloutView.window) {
        [self.calloutView dismissCalloutAnimated:animated];
    }
    
    if (self.overlayDimmingView) {
        self.overlayDimmingView.delegate = nil;
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^{
                self.overlayDimmingView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.0];
            } completion:^(BOOL finished) {
                [self.overlayDimmingView removeFromSuperview];
                self.overlayDimmingView = nil;
            }];
        }
        else {
            [self.overlayDimmingView removeFromSuperview];
            self.overlayDimmingView = nil;
        }
    }
}

- (void)calloutViewDidDisappear:(SMCalloutView *)calloutView {
    UIViewController *viewController = self.selectedViewController;
    if ([viewController conformsToProtocol:@protocol(GuideViewDismissedListener)]) {
        id<GuideViewDismissedListener> guideViewController = (id<GuideViewDismissedListener>)viewController;
        [guideViewController guideViewDismissed];
    }
}

@end
