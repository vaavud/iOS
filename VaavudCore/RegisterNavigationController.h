////
////  RegisterNavigationViewController.h
////  Vaavud
////
////  Created by Thomas Stilling Ambus on 11/02/2014.
////  Copyright (c) 2014 Andreas Okholm. All rights reserved.
////
//
//#import <UIKit/UIKit.h>
//
//enum RegisterScreenType : NSUInteger {
//    RegisterScreenTypeLogIn = 1,
//    RegisterScreenTypeSignUp = 2,
//};
//
//@protocol RegisterNavigationControllerDelegate <NSObject>
//- (void)userAuthenticated:(BOOL)isSignup viewController:(UIViewController *)viewController;
//- (void)cancelled:(UIViewController *)viewController;
//- (NSString *)registerScreenTitle;
//- (NSString *)registerTeaserText;
//@end
//
//@interface RegisterNavigationController : UINavigationController
//
//@property (nonatomic, weak) id<RegisterNavigationControllerDelegate> registerDelegate;
//@property (nonatomic) NSUInteger startScreen;
//@property (nonatomic, copy) void (^completion)(void);
//
//@end
//
//
@interface RotatableNavigationController : UINavigationController

@end
