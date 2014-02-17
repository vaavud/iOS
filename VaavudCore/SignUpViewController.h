//
//  SignUpViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 07/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "vaavudAppDelegate.h"
#import "GuidedTextField.h"

@interface SignUpViewController : UIViewController <GuidedTextFieldDelegate, FacebookAuthenticationDelegate>

@end
