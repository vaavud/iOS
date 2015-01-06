//
//  GuidedTextField.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 05/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "GuidedTextField.h"

@interface GuidedTextField ()

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

- (void)initSelf {
    [self initGuide];
}

- (void)initGuide {
    self.isFirstEdit = YES;
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    self.label.text = self.guideText;
    [self addSubview:self.label];
    self.label.font = [UIFont systemFontOfSize:self.font.pointSize];
    self.label.textColor = [UIColor lightGrayColor];
}

- (void)setGuideText:(NSString *)guideText {
    _guideText = guideText;
    self.label.text = guideText;
}

@end
