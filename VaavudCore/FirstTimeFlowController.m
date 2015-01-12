//
//  FirstTimeFlowController.m
//  Feast
//
//  Created by Thomas Stilling Ambus on 17/04/2014.
//  Copyright (c) 2014 Thomas Stilling Ambus. All rights reserved.
//

#import "FirstTimeFlowController.h"
#import "Mixpanel.h"
#import "Property+Util.h"
#import "AccountManager.h"
#import "ServerUploadManager.h"
#import "TabBarController.h"

@interface FirstTimeFlowController ()

@property (nonatomic) UIPageViewController *pageController;
@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UINavigationBar *customNavigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *customNavigationItem;
@property (nonatomic) BOOL returnViaDismiss;
@property (nonatomic) BOOL useBorderlessBuyLaterButton;

@end

@implementation FirstTimeFlowController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    //NSLog(@"[FirstTimeFlowController] isLoggedIn=%@, hasWindMeter=%@", [AccountManager sharedInstance].isLoggedIn ? @"YES" : @"NO", [Property getAsBoolean:KEY_USER_HAS_WIND_METER defaultValue:NO] ? @"YES" : @"NO");
    
    if (!self.pageImages) {
        if ([AccountManager sharedInstance].isLoggedIn && [Property getAsBoolean:KEY_USER_HAS_WIND_METER defaultValue:NO]) {
            [FirstTimeFlowController createInstructionFlowOn:self];
        }
        else {
            self.pageImages = @[@"001_basejumper.jpg", @"002_map.jpg", @"003_sign_up.jpg"];
            self.pageTexts = @[NSLocalizedString(@"INTRO_FLOW_SCREEN_1", nil), NSLocalizedString(@"INTRO_FLOW_SCREEN_2", nil), @""];
            self.pageMixpanelScreens = @[@"Intro Flow Screen 1", @"Intro Flow Screen 2", @"Intro Flow Register Screen"];
            self.pageIds = @[@0, @1, @2];
        }
    }
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    
    // We need to cover all the control by making the frame taller (+ 37)
    [[self.pageController view] setFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height + 37)];
    
    UIViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];

    /* Navigation bar */
    
    [self.customNavigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.customNavigationBar.shadowImage = [UIImage new];
    self.customNavigationBar.translucent = YES;
    self.customNavigationBar.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor clearColor];
    self.customNavigationBar.tintColor = [UIColor whiteColor];
    
    self.customNavigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]];
    
    // Bring the common controls to the foreground (they were hidden since the frame is taller)
    [self.view bringSubviewToFront:self.pageControl];
    [self.view bringSubviewToFront:self.customNavigationBar];    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {

    NSUInteger index = [self indexForViewController:viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {

    NSUInteger index = [self indexForViewController:viewController];
    if (index == NSNotFound) {
        return nil;
    }
    index++;
    if (index == [self.pageImages count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    if (([self.pageImages count] == 0) || (index >= [self.pageImages count])) {
        return nil;
    }
    
    FirstTimeExplanationViewController *explanationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTimeExplanationViewController"];
    explanationViewController.delegate = self;
    explanationViewController.imageName = self.pageImages[index];
    explanationViewController.pageIndex = index;
    explanationViewController.pageId = [self.pageIds[index] integerValue];
    explanationViewController.mixpanelScreen = self.pageMixpanelScreens[index];
    explanationViewController.explanationText = self.pageTexts[index];
    explanationViewController.bottomButtonIsTransparent = NO;
    explanationViewController.tinyButtonIsSolid = NO;

    if (explanationViewController.pageId == 2) {
        if ([AccountManager sharedInstance].isLoggedIn) {
            explanationViewController = [self createHaveWindMeterController];
            explanationViewController.pageIndex = index;
        }
        else {
            explanationViewController.topButtonText = NSLocalizedString(@"REGISTER_TITLE_SIGNUP", nil);
            explanationViewController.bottomButtonText = NSLocalizedString(@"REGISTER_TITLE_LOGIN", nil);
            explanationViewController.tinyButtonText = NSLocalizedString(@"INTRO_FLOW_BUTTON_SKIP", nil);
        }
    }
    
    if (explanationViewController.pageId == 8) {
        explanationViewController.tinyButtonText = NSLocalizedString(@"INTRO_FLOW_BUTTON_GOT_IT", nil);
        explanationViewController.tinyButtonIsSolid = YES;
    }
    
    return explanationViewController;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    NSInteger numOfPages = [self.pageImages count];
    [self.pageControl setNumberOfPages:numOfPages];
    return numOfPages;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return 0;
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed {

    if (completed) {
        [self syncCustomPageControl];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController
willTransitionToViewControllers:(NSArray *)pendingViewControllers {

}

- (void)syncCustomPageControl {
    NSArray *controllers = self.pageController.viewControllers;
    if (controllers.count > 0) {
        NSUInteger index = [self indexForViewController:controllers[0]];
        [self.pageControl setCurrentPage:index];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (NSInteger)indexForViewController:(UIViewController *)viewController {
    return ((FirstTimeExplanationViewController *)viewController).pageIndex;
}

- (void)topButtonPushedOnController:(FirstTimeExplanationViewController *)controller {
    if (controller.pageId == 2) {
        UIStoryboard *loginStoryBoard = [UIStoryboard storyboardWithName:@"Register" bundle:nil];
        RegisterNavigationController *newController = [loginStoryBoard instantiateInitialViewController];
        if ([newController isKindOfClass:[RegisterNavigationController class]]) {
            newController.registerDelegate = self;
            newController.startScreen = RegisterScreenTypeSignUp;
            [self presentViewController:newController animated:YES completion:nil];
        }
    }
    else if (controller.pageId == 3) {
        [Property setAsBoolean:YES forKey:KEY_USER_HAS_WIND_METER];

        [FirstTimeFlowController gotoInstructionFlowFrom:controller returnViaDismiss:NO];
    }
    else if (controller.pageId == 4) {
        [[Mixpanel sharedInstance] track:@"Intro Flow Clicked Buy" properties:@{@"Borderless Later Button": self.useBorderlessBuyLaterButton ? @"true" : @"false"}];
        
        NSString *country = [Property getAsString:KEY_COUNTRY];
        NSString *language = [Property getAsString:KEY_LANGUAGE];
        NSString *mixpanelId = [Mixpanel sharedInstance].distinctId;
        NSString *url = [NSString stringWithFormat:@"http://vaavud.com/mobile-shop-redirect/?country=%@&language=%@&ref=%@&source=intro", country, language, mixpanelId];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
}

- (void)bottomButtonPushedOnController:(FirstTimeExplanationViewController *)controller {
    if (controller.pageId == 2) {
        UIStoryboard *loginStoryBoard = [UIStoryboard storyboardWithName:@"Register" bundle:nil];
        RegisterNavigationController *newController = (RegisterNavigationController*) [loginStoryBoard instantiateInitialViewController];
        if ([newController isKindOfClass:[RegisterNavigationController class]]) {
            newController.registerDelegate = self;
            newController.startScreen = RegisterScreenTypeLogIn;
            [self presentViewController:newController animated:YES completion:nil];
        }
    }
    else if (controller.pageId == 3) {
        self.useBorderlessBuyLaterButton = (arc4random_uniform(2) == 1);
        
        FirstTimeExplanationViewController *explanationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTimeExplanationViewController"];
        explanationViewController.delegate = self;
        explanationViewController.imageName = @"004_wind_meter.jpg";
        explanationViewController.pageIndex = 0;
        explanationViewController.pageId = 4;
        explanationViewController.mixpanelScreen = @"Intro Flow Buy Screen";
        explanationViewController.topExplanationText = NSLocalizedString(@"INTRO_FLOW_WANT_TO_BUY", nil);
        explanationViewController.topButtonText = NSLocalizedString(@"BUTTON_YES", nil);
        explanationViewController.bottomButtonText = NSLocalizedString(@"INTRO_FLOW_BUTTON_LATER", nil);
        explanationViewController.bottomButtonIsTransparent = NO;
        
        if (self.useBorderlessBuyLaterButton) {
            explanationViewController.bottomButtonIsTransparent = YES;
        }
        
        [controller presentViewController:explanationViewController animated:NO completion:nil];
    }
    else if (controller.pageId == 4) {
        if ([Property getAsBoolean:KEY_USER_HAS_WIND_METER defaultValue:NO]) {
            [FirstTimeFlowController gotoInstructionFlowFrom:controller returnViaDismiss:NO];
        }
        else {
            [self gotoMainScreenFromController:controller];
        }
    }
}

- (void)tinyButtonPushedOnController:(FirstTimeExplanationViewController *)controller {
    if (controller.pageId == 2) {
        [self gotoNewFlowScreenFrom:controller];
    }
    else if (controller.pageId == 8) {
        if (self.returnViaDismiss) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            [self gotoMainScreenFromController:controller];
        }
    }
}

- (void)gotoMainScreenFromController:(UIViewController *)controller {
    [Property setAsBoolean:YES forKey:KEY_HAS_SEEN_INTRO_FLOW];
    
    TabBarController *nextViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TabBarController"];
    if (![Property getAsBoolean:KEY_USER_HAS_WIND_METER defaultValue:NO]) {
        nextViewController.selectedIndex = 1;
    }
    [UIApplication sharedApplication].delegate.window.rootViewController = nextViewController;
    
    if ([AccountManager sharedInstance].isLoggedIn) {
        [[ServerUploadManager sharedInstance] syncHistory:2 ignoreGracePeriod:YES success:nil failure:nil];
    }
}

- (void)continueFlowFromController:(FirstTimeExplanationViewController *)controller {
    if (controller.pageId == 4) {
        if ([Property getAsBoolean:KEY_USER_HAS_WIND_METER defaultValue:NO]) {
            [FirstTimeFlowController gotoInstructionFlowFrom:controller returnViaDismiss:NO];
        }
        else {
            [self gotoMainScreenFromController:controller];
        }
    }
}

- (void)userAuthenticated:(BOOL)isSignup viewController:(UIViewController *)viewController {
    [self gotoNewFlowScreenFrom:viewController];
}

- (void)cancelled:(UIViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)registerScreenTitle {
    return nil;
}

- (NSString *)registerTeaserText {
    return nil;
}

- (void)gotoNewFlowScreenFrom:(UIViewController *)viewController {
    if ([Property getAsBoolean:KEY_USER_HAS_WIND_METER defaultValue:NO]) {
        [FirstTimeFlowController gotoInstructionFlowFrom:viewController returnViaDismiss:NO];
    }
    else {
        UIViewController *explanationViewController = [self createHaveWindMeterController];
        explanationViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [viewController presentViewController:explanationViewController animated:YES completion:nil];
    }
}

- (FirstTimeExplanationViewController *)createHaveWindMeterController {
    FirstTimeExplanationViewController *explanationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTimeExplanationViewController"];
    explanationViewController.delegate = self;
    explanationViewController.imageName = @"004_wind_meter.jpg";
    explanationViewController.pageIndex = 0;
    explanationViewController.pageId = 3;
    explanationViewController.mixpanelScreen = @"Intro Flow Have Wind Meter Screen";
    explanationViewController.topExplanationText = NSLocalizedString(@"INTRO_FLOW_HAVE_WIND_METER", nil);
    explanationViewController.topButtonText = NSLocalizedString(@"BUTTON_YES", nil);
    explanationViewController.bottomButtonText = NSLocalizedString(@"BUTTON_NO", nil);
    explanationViewController.bottomButtonIsTransparent = NO;
    return explanationViewController;
}

+ (void)gotoInstructionFlowFrom:(UIViewController*)viewController returnViaDismiss:(BOOL)returnViaDismiss {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    FirstTimeFlowController *newViewController = [storyboard instantiateViewControllerWithIdentifier:@"FirstTimeFlowController"];
    [FirstTimeFlowController createInstructionFlowOn:newViewController];
    newViewController.returnViaDismiss = returnViaDismiss;
    
    newViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [viewController presentViewController:newViewController animated:YES completion:nil];
}

+ (void)createInstructionFlowOn:(FirstTimeFlowController *)controller {
    controller.pageImages = @[@"005_paraglider.jpg", @"006_hold_top.jpg", @"006_open_space.jpg", @"007_reading.jpg"];
    controller.pageTexts = @[NSLocalizedString(@"INSTRUCTION_FLOW_SCREEN_1", nil), NSLocalizedString(@"INSTRUCTION_FLOW_SCREEN_2", nil), NSLocalizedString(@"INSTRUCTION_FLOW_SCREEN_3", nil), NSLocalizedString(@"INSTRUCTION_FLOW_SCREEN_4", nil)];
    controller.pageIds = @[@5, @6, @7, @8];
    controller.pageMixpanelScreens = @[@"Instruction Flow Screen 1", @"Instruction Flow Screen 2", @"Instruction Flow Screen 3", @"Instruction Flow Screen 4"];
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
