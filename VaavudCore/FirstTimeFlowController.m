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

@interface FirstTimeFlowController ()

@property (strong, nonatomic) NSArray *pageImages;
@property (strong, nonatomic) NSArray *pageTexts;
@property (nonatomic) UIPageViewController *pageController;
@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UINavigationBar *customNavigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *customNavigationItem;

@end

@implementation FirstTimeFlowController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.pageImages = @[@"FirstTime-1.jpg", @"FirstTime-2.jpg", @"FirstTime-3.jpg"];
    self.pageTexts = @[NSLocalizedString(@"INTRO_FLOW_SCREEN_1", nil), NSLocalizedString(@"INTRO_FLOW_SCREEN_2", nil), @""];
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    
    // We need to cover all the control by making the frame taller (+ 37)
    [[self.pageController view] setFrame:CGRectMake(0, 0, [[self view] bounds].size.width, [[self view] bounds].size.height + 37)];
    
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
    //if ([Property isMixpanelEnabled]) [[Mixpanel sharedInstance] track:@"Explanation Flow Screen"];
}

- (UIViewController*) pageViewController:(UIPageViewController*)pageViewController viewControllerBeforeViewController:(UIViewController*)viewController {

    NSUInteger index = [self indexForViewController:viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController*) pageViewController:(UIPageViewController*)pageViewController viewControllerAfterViewController:(UIViewController*)viewController {

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

- (UIViewController*) viewControllerAtIndex:(NSUInteger)index {
    
    if (([self.pageImages count] == 0) || (index >= [self.pageImages count])) {
        return nil;
    }
    
    FirstTimeExplanationViewController *explanationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTimeExplanationViewController"];
    explanationViewController.delegate = self;
    explanationViewController.imageName = self.pageImages[index];
    explanationViewController.pageIndex = index;

    if (index < 2) {
        explanationViewController.explanationText = self.pageTexts[index];
    }
    else if (index == 2) {
        explanationViewController.topButtonText = NSLocalizedString(@"REGISTER_TITLE_SIGNUP", nil);
        explanationViewController.bottomButtonText = NSLocalizedString(@"REGISTER_TITLE_LOGIN", nil);
        explanationViewController.tinyButtonText = NSLocalizedString(@"INTRO_FLOW_BUTTON_SKIP", nil);
    }
    
    return explanationViewController;
}

- (NSInteger) presentationCountForPageViewController:(UIPageViewController*)pageViewController {
    NSInteger numOfPages = [self.pageImages count];
    [self.pageControl setNumberOfPages:numOfPages];
    return numOfPages;
}

- (NSInteger) presentationIndexForPageViewController:(UIPageViewController*)pageViewController {
    return 0;
}

- (void) pageViewController:(UIPageViewController*)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray*)previousViewControllers transitionCompleted:(BOOL)completed {

    if (completed) {
        [self syncCustomPageControl];
    }
}

- (void) pageViewController:(UIPageViewController*)pageViewController willTransitionToViewControllers:(NSArray*)pendingViewControllers {

}

- (void) syncCustomPageControl {
    NSArray *controllers = self.pageController.viewControllers;
    if (controllers.count > 0) {
        NSUInteger index = [self indexForViewController:controllers[0]];
        [self.pageControl setCurrentPage:index];
    }
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (NSInteger) indexForViewController:(UIViewController*)viewController {
    return ((FirstTimeExplanationViewController*) viewController).pageIndex;
}

- (void) topButtonPushedOnController:(FirstTimeExplanationViewController*)controller {
    
    if (controller.pageIndex == 2) {
        UIStoryboard *loginStoryBoard = [UIStoryboard storyboardWithName:@"Register" bundle:nil];
        RegisterNavigationController *newController = (RegisterNavigationController*) [loginStoryBoard instantiateInitialViewController];
        if ([newController isKindOfClass:[RegisterNavigationController class]]) {
            newController.registerDelegate = self;
            newController.startScreen = RegisterScreenTypeSignUp;
            [self presentViewController:newController animated:YES completion:nil];
        }
    }
    else if (controller.pageIndex == 4) {
        
        NSString *country = [Property getAsString:KEY_COUNTRY];
        NSString *language = [Property getAsString:KEY_LANGUAGE];
        NSString *url = [NSString stringWithFormat:@"http://vaavud.com/mobile-shop-redirect/?country=%@&language=%@", country, language];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        
        // TODO: make sure to display next step in flow when user returns - maybe set a flag and do a transition when becoming active
    }
}

- (void) bottomButtonPushedOnController:(FirstTimeExplanationViewController*)controller {
    
    if (controller.pageIndex == 2) {
        UIStoryboard *loginStoryBoard = [UIStoryboard storyboardWithName:@"Register" bundle:nil];
        RegisterNavigationController *newController = (RegisterNavigationController*) [loginStoryBoard instantiateInitialViewController];
        if ([newController isKindOfClass:[RegisterNavigationController class]]) {
            newController.registerDelegate = self;
            newController.startScreen = RegisterScreenTypeLogIn;
            [self presentViewController:newController animated:YES completion:nil];
        }
    }
    else if (controller.pageIndex == 3) {

        FirstTimeExplanationViewController *explanationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTimeExplanationViewController"];
        explanationViewController.delegate = self;
        explanationViewController.imageName = @"FirstTime-3.jpg";
        explanationViewController.pageIndex = 4;
        explanationViewController.topExplanationText = NSLocalizedString(@"INTRO_FLOW_WANT_TO_BUY", nil);
        explanationViewController.topButtonText = NSLocalizedString(@"BUTTON_YES", nil);
        explanationViewController.bottomButtonText = NSLocalizedString(@"INTRO_FLOW_BUTTON_LATER", nil);
        explanationViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [controller presentViewController:explanationViewController animated:YES completion:nil];
    }
}

- (void) tinyButtonPushedOnController:(FirstTimeExplanationViewController*)controller {
    
    if (controller.pageIndex == 2) {
        [self gotoNewFlowScreenFrom:controller];
    }
}

- (void) userAuthenticated:(BOOL)isSignup viewController:(UIViewController*)viewController {
    
    //UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    //UIViewController *nextViewController = [storyboard instantiateViewControllerWithIdentifier:@"TabBarController"];
    //self.window.rootViewController = nextViewController;
    
    //[[ServerUploadManager sharedInstance] syncHistory:1 ignoreGracePeriod:YES success:nil failure:nil];
    
    [self gotoNewFlowScreenFrom:viewController];
}

- (void) cancelled:(UIViewController*)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (NSString*) registerScreenTitle {
    return nil;
}

- (NSString*) registerTeaserText {
    return nil;
}

- (void) gotoNewFlowScreenFrom:(UIViewController*)viewController {
    
    if ([Property getAsBoolean:KEY_USER_HAS_WIND_METER defaultValue:NO]) {
        // TODO: go to instruction flow
    }
    else {
        FirstTimeExplanationViewController *explanationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTimeExplanationViewController"];
        explanationViewController.delegate = self;
        explanationViewController.imageName = @"FirstTime-3.jpg";
        explanationViewController.pageIndex = 3;
        explanationViewController.topExplanationText = NSLocalizedString(@"INTRO_FLOW_HAVE_WIND_METER", nil);
        explanationViewController.topButtonText = NSLocalizedString(@"BUTTON_YES", nil);
        explanationViewController.bottomButtonText = NSLocalizedString(@"BUTTON_NO", nil);
        explanationViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [viewController presentViewController:explanationViewController animated:YES completion:nil];
    }
}

@end
