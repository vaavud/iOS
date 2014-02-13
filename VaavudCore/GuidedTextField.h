//
//  GuidedTextField.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 05/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GuidedTextFieldDelegate <NSObject>
@optional
- (void) changedEmptiness:(UITextField*)textField isEmpty:(BOOL)isEmpty;
- (BOOL) textFieldShouldReturn:(UITextField*)textField;
@end

@interface GuidedTextField : UITextField <UITextFieldDelegate>

@property (nonatomic, weak) id<GuidedTextFieldDelegate> guidedDelegate;
@property (nonatomic) NSString *guideText;

@end
