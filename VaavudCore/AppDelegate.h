//
//  vaavudAppDelegate.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <FacebookSDK/FacebookSDK.h>
#import "RegisterNavigationController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, RegisterNavigationControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) NSString *xCallbackSuccess;

@end
