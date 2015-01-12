//
//  DismissOnTouchUIView.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 04/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "DismissOnTouchUIView.h"

@implementation DismissOnTouchUIView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (self.delegate) {
                [self.delegate dismissOverlayView];
                self.delegate = nil;
            }
        }];
        
        return nil;
    }
    
    return hitView;
}

@end
