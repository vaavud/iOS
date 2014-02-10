//
//  GuidedTextField.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 05/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GuidedTextField : UITextField <UITextFieldDelegate>

@property (nonatomic) NSString *guideText;

@end
