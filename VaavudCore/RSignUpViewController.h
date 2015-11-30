//
//  SignUpViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 07/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountManager.h"

@interface RSignUpViewController : UIViewController <AuthenticationDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, copy) void (^completion)(void);

@end
