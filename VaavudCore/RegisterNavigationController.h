//
//  RegisterNavigationViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RegisterNavigationControllerDelegate
- (void) userAuthenticated;
@end

@interface RegisterNavigationController : UINavigationController

@property (nonatomic, weak) id<RegisterNavigationControllerDelegate> registerDelegate;

@end
