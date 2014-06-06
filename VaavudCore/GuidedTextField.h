//
//  GuidedTextField.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 05/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GuidedTextField : UITextField

@property (nonatomic) NSString *guideText;
@property (nonatomic) UILabel *label;
@property (nonatomic) BOOL isFirstEdit;

@end
