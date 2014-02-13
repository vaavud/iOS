//
//  GuidedTextField.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 05/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "GuidedTextField.h"

@interface GuidedTextField ()

@property (nonatomic) UILabel *label;

@end

@implementation GuidedTextField

BOOL isFirstEdit = YES;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSelf];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initSelf];
    }
    return self;
}

- (void) initSelf {
    self.delegate = self;
    [self initGuide];
}

- (void)initGuide {
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    self.label.text = self.guideText;
    [self addSubview:self.label];
    self.label.font = [UIFont systemFontOfSize:self.font.pointSize];
    self.label.textColor = [UIColor lightGrayColor];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSRange textFieldRange = NSMakeRange(0, [textField.text length]);
    if ((NSEqualRanges(range, textFieldRange) && [string length] == 0) || (textField.secureTextEntry && isFirstEdit && range.location > 0 && range.length == 1 && string.length == 0)) {
        if (self.label.hidden) {
            self.label.hidden = NO;
            if (self.guidedDelegate && [self.guidedDelegate respondsToSelector:@selector(changedEmptiness:isEmpty:)]) {
                [self.guidedDelegate changedEmptiness:textField isEmpty:YES];
            }
        }
    }
    else {
        if (!self.label.hidden) {
            self.label.hidden = YES;
            if (self.guidedDelegate && [self.guidedDelegate respondsToSelector:@selector(changedEmptiness:isEmpty:)]) {
                [self.guidedDelegate changedEmptiness:textField isEmpty:NO];
            }
        }
    }
    
    isFirstEdit = NO;
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.guidedDelegate && [self.guidedDelegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
        return [self.guidedDelegate textFieldShouldReturn:textField];
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    isFirstEdit = YES;
    return YES;
}

- (void)setGuideText:(NSString *)guideText {
    _guideText = guideText;
    self.label.text = guideText;
}

@end
