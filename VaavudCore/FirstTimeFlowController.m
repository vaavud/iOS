//
//  FirstTimeFlowController.m
//  Feast
//
//  Created by Thomas Stilling Ambus on 17/04/2014.
//  Copyright (c) 2014 Thomas Stilling Ambus. All rights reserved.
//

#import "FirstTimeFlowController.h"
#import "FirstTimeExplanationViewController.h"
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
    
    self.pageImages = @[@"FirstTime-1.jpg", @"FirstTime-2.jpg", @"FirstTime-3.jpg" /*, @"FirstTime-4.jpg"*/];
    self.pageTexts = @[
            @"The rugged, electronicless Vaavud wind meter turns your smartphone into a high-tech meteorological tool.",
            @"Watch live wind measurements on a map and know how the conditions are at your favorite spot.",
            @"Do you already have the Vaavud wind meter?" /*,
            @"To take a proper wind measurement, plug in the wind meter and hold it up against the wind facing the display towards yourself."*/];
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    
    // We need to cover all the control by making the frame taller (+ 37)
    [[self.pageController view] setFrame:CGRectMake(0, 0, [[self view] bounds].size.width, [[self view] bounds].size.height + 37)];
    
    FirstTimeExplanationViewController *startingViewController = [self viewControllerAtIndex:0];
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

    NSUInteger index = ((FirstTimeExplanationViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController*) pageViewController:(UIPageViewController*)pageViewController viewControllerAfterViewController:(UIViewController*)viewController {

    NSUInteger index = ((FirstTimeExplanationViewController*) viewController).pageIndex;

    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.pageImages count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (FirstTimeExplanationViewController*) viewControllerAtIndex:(NSUInteger)index {
    if (([self.pageImages count] == 0) || (index >= [self.pageImages count])) {
        return nil;
    }
    
    FirstTimeExplanationViewController *explanationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstTimeExplanationViewController"];
    explanationViewController.imageName = self.pageImages[index];
    explanationViewController.explanationText = self.pageTexts[index];
    explanationViewController.pageIndex = index;
    explanationViewController.showFinishButton = NO;
    
    if (index != 2) {
        explanationViewController.textVerticalMiddle = YES;
    }
    else {
        explanationViewController.textVerticalMiddle = NO;
    }
    
    if (index == 2) {
        explanationViewController.showQuestionButtons = YES;
    }
    else {
        explanationViewController.showQuestionButtons = NO;
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
        NSUInteger index = ((FirstTimeExplanationViewController*) controllers[0]).pageIndex;
        [self.pageControl setCurrentPage:index];
    }
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

@end
