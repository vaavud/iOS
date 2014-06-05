//
//  TransitionController.m
//
//  Created by XJones on 11/25/11.
//

#import "TransitionController.h"

@implementation TransitionController

- (id) initWithViewController:(UIViewController*)viewController {
    if (self = [super init]) {
        _viewController = viewController;
    }
    return self;
}

- (void) loadView {
    self.wantsFullScreenLayout = YES;
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.view = view;
    
    _containerView = [[UIView alloc] initWithFrame:view.bounds];
    _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_containerView];
    
    [_containerView addSubview:self.viewController.view];
}

- (NSUInteger) supportedInterfaceOrientations {
    return [self.viewController supportedInterfaceOrientations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [self.viewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.viewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.viewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)transitionToViewController:(UIViewController*)aViewController withOptions:(UIViewAnimationOptions)options {
    aViewController.view.frame = self.containerView.bounds;
    [UIView transitionWithView:self.containerView
                      duration:0.65f
                       options:options
                    animations:^{
                        [self.viewController.view removeFromSuperview];
                        [self.containerView addSubview:aViewController.view];
                    }
                    completion:^(BOOL finished){
                        self.viewController = aViewController;
                    }];
}

@end
