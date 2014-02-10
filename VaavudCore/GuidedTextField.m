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

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.label.hidden = YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.text.length == 0) {
        self.label.hidden = NO;
    }
}

- (void)setGuideText:(NSString *)guideText {
    _guideText = guideText;
    self.label.text = guideText;
}

@end
