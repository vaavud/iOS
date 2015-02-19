//
//  NoHistoryArrowView.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 27/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#define TIP_BOTTOM_SPACING 20.0
#define TIP_LEFT_SPACING 34.0
#define ARROW_HALF_WIDTH 15.0
#define ARROW_HEIGHT 30.0

#import "NoHistoryArrowView.h"
#import "UIColor+VaavudColors.h"

@implementation NoHistoryArrowView

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColorWithColor(context, [UIColor vaavudColor].CGColor);
    
    CGFloat dashArray[] = {8,4};
    CGContextSetLineDash(context, 0, dashArray, 2);
    CGContextMoveToPoint(context, self.bounds.size.width - 60.0, 20.0);
    CGContextAddQuadCurveToPoint(context, 34.0, 20.0, TIP_LEFT_SPACING, self.bounds.size.height - TIP_BOTTOM_SPACING);
    CGContextStrokePath(context);

    CGContextSetLineDash(context, 0, dashArray, 2);
    CGContextMoveToPoint(context, TIP_LEFT_SPACING, self.bounds.size.height - TIP_BOTTOM_SPACING);
    CGContextAddLineToPoint(context, TIP_LEFT_SPACING - ARROW_HALF_WIDTH, self.bounds.size.height - TIP_BOTTOM_SPACING - ARROW_HEIGHT);
    CGContextStrokePath(context);

    CGContextSetLineDash(context, 0, dashArray, 2);
    CGContextMoveToPoint(context, TIP_LEFT_SPACING, self.bounds.size.height - TIP_BOTTOM_SPACING);
    CGContextAddLineToPoint(context, TIP_LEFT_SPACING + ARROW_HALF_WIDTH, self.bounds.size.height - TIP_BOTTOM_SPACING - ARROW_HEIGHT);
    CGContextStrokePath(context);
}

@end
