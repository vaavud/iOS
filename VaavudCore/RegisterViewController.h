//
//  LoginRootViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 07/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegisterViewController : UIViewController

@property (nonatomic) NSString *teaserLabelText;

@property (nonatomic, copy) void (^completion)(void);

@property (nonatomic) BOOL showCancelButton;

@end
