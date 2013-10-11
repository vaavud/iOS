//
//  CustomSMCalloutDrawnBackgroundView.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 27/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "CustomSMCalloutDrawnBackgroundView.h"

#define TOP_SHADOW_BUFFER 2 // height offset buffer to account for top shadow
#define BOTTOM_SHADOW_BUFFER 5 // height offset buffer to account for bottom shadow
#define OFFSET_FROM_ORIGIN 5 // distance to offset vertically from the rect origin of the callout
#define ANCHOR_HEIGHT 14 // height to use for the anchor
#define ANCHOR_MARGIN_MIN 24 // the smallest possible distance from the edge of our control to the edge of the anchor, from either left or right

@interface UIView (SMFrameAdditions)
@property (nonatomic, assign) CGPoint $origin;
@property (nonatomic, assign) CGSize $size;
@property (nonatomic, assign) CGFloat $x, $y, $width, $height; // normal rect properties
@property (nonatomic, assign) CGFloat $left, $top, $right, $bottom; // these will stretch/shrink the rect
@end

@implementation CustomSMCalloutDrawnBackgroundView

- (void)drawRect:(CGRect)rect {
    
    BOOL pointingUp = self.arrowPoint.y < self.$height/2;
    CGSize anchorSize = CGSizeMake(27, ANCHOR_HEIGHT);
    CGFloat anchorX = roundf(self.arrowPoint.x - anchorSize.width / 2);
    CGRect anchorRect = CGRectMake(anchorX, 0, anchorSize.width, anchorSize.height);
    
    // make sure the anchor is not too close to the end caps
    if (anchorRect.origin.x < ANCHOR_MARGIN_MIN) {
        anchorRect.origin.x = ANCHOR_MARGIN_MIN;
    }
    else if (anchorRect.origin.x + anchorRect.size.width > self.$width - ANCHOR_MARGIN_MIN) {
        anchorRect.origin.x = self.$width - anchorRect.size.width - ANCHOR_MARGIN_MIN;
    }
    
    // determine size
    CGFloat stroke = 1.0;
    CGFloat radius = [UIScreen mainScreen].scale == 1 ? 4.5 : 6.0;
    
    rect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + TOP_SHADOW_BUFFER, self.bounds.size.width, self.bounds.size.height - ANCHOR_HEIGHT);
    rect.size.width -= stroke + 14;
    rect.size.height -= stroke * 2 + TOP_SHADOW_BUFFER + BOTTOM_SHADOW_BUFFER + OFFSET_FROM_ORIGIN;
    rect.origin.x += stroke / 2.0 + 7;
    rect.origin.y += pointingUp ? ANCHOR_HEIGHT - stroke / 2.0 : stroke / 2.0;
    
    // General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Color Declarations
    UIColor* fillBlack = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    UIColor* shadowBlack = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.3];
    UIColor* strokeColor = [UIColor colorWithRed: 0.1 green: 0.1 blue: 0.1 alpha: 1];
    
    // Shadow Declarations
    UIColor* baseShadow = shadowBlack;
    CGSize baseShadowOffset = CGSizeMake(0.1, 6.1);
    CGFloat baseShadowBlurRadius = 6;
    
    CGFloat backgroundStrokeWidth = 0.5; // TODO: try smaller :-)
    
    // Frames
    CGRect frame = rect;
    
    CGContextSaveGState(context);
    CGContextSetAlpha(context, 0.95);
    CGContextBeginTransparencyLayer(context, NULL);
    
    // Background Drawing
    UIBezierPath* backgroundPath = [UIBezierPath bezierPath];
    [backgroundPath moveToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame) + radius)];
    [backgroundPath addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) - radius)]; // left
    [backgroundPath addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame) - radius) radius:radius startAngle:M_PI endAngle:M_PI / 2 clockwise:NO]; // bottom-left corner
    
    // pointer down
    if (!pointingUp) {
        [backgroundPath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect), CGRectGetMaxY(frame))];
        [backgroundPath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect) + anchorRect.size.width / 2, CGRectGetMaxY(frame) + anchorRect.size.height)];
        [backgroundPath addLineToPoint:CGPointMake(CGRectGetMaxX(anchorRect), CGRectGetMaxY(frame))];
    }
    
    [backgroundPath addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame))]; // bottom
    [backgroundPath addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame) - radius) radius:radius startAngle:M_PI / 2 endAngle:0.0f clockwise:NO]; // bottom-right corner
    [backgroundPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame), CGRectGetMinY(frame) + radius)]; // right
    [backgroundPath addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame) + radius) radius:radius startAngle:0.0f endAngle:-M_PI / 2 clockwise:NO]; // top-right corner
    
    // pointer up
    if (pointingUp) {
        [backgroundPath addLineToPoint:CGPointMake(CGRectGetMaxX(anchorRect), CGRectGetMinY(frame))];
        [backgroundPath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect) + anchorRect.size.width / 2, CGRectGetMinY(frame) - anchorRect.size.height)];
        [backgroundPath addLineToPoint:CGPointMake(CGRectGetMinX(anchorRect), CGRectGetMinY(frame))];
    }
    
    [backgroundPath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame))]; // top
    [backgroundPath addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame) + radius) radius:radius startAngle:-M_PI / 2 endAngle:M_PI clockwise:NO]; // top-left corner
    [backgroundPath closePath];
    
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, baseShadowOffset, baseShadowBlurRadius, baseShadow.CGColor);
    [fillBlack setFill];
    [backgroundPath fill];
    CGContextRestoreGState(context);
    
    [strokeColor setStroke];
    backgroundPath.lineWidth = backgroundStrokeWidth;
    [backgroundPath stroke];
    
    CGContextEndTransparencyLayer(context);
    CGContextRestoreGState(context);
    
    //// Cleanup
    CGColorSpaceRelease(colorSpace);
}

@end

@implementation UIView (SMFrameAdditions)

- (CGPoint)$origin { return self.frame.origin; }
- (void)set$origin:(CGPoint)origin { self.frame = (CGRect){ .origin=origin, .size=self.frame.size }; }

- (CGFloat)$x { return self.frame.origin.x; }
- (void)set$x:(CGFloat)x { self.frame = (CGRect){ .origin.x=x, .origin.y=self.frame.origin.y, .size=self.frame.size }; }

- (CGFloat)$y { return self.frame.origin.y; }
- (void)set$y:(CGFloat)y { self.frame = (CGRect){ .origin.x=self.frame.origin.x, .origin.y=y, .size=self.frame.size }; }

- (CGSize)$size { return self.frame.size; }
- (void)set$size:(CGSize)size { self.frame = (CGRect){ .origin=self.frame.origin, .size=size }; }

- (CGFloat)$width { return self.frame.size.width; }
- (void)set$width:(CGFloat)width { self.frame = (CGRect){ .origin=self.frame.origin, .size.width=width, .size.height=self.frame.size.height }; }

- (CGFloat)$height { return self.frame.size.height; }
- (void)set$height:(CGFloat)height { self.frame = (CGRect){ .origin=self.frame.origin, .size.width=self.frame.size.width, .size.height=height }; }

- (CGFloat)$left { return self.frame.origin.x; }
- (void)set$left:(CGFloat)left { self.frame = (CGRect){ .origin.x=left, .origin.y=self.frame.origin.y, .size.width=fmaxf(self.frame.origin.x+self.frame.size.width-left,0), .size.height=self.frame.size.height }; }

- (CGFloat)$top { return self.frame.origin.y; }
- (void)set$top:(CGFloat)top { self.frame = (CGRect){ .origin.x=self.frame.origin.x, .origin.y=top, .size.width=self.frame.size.width, .size.height=fmaxf(self.frame.origin.y+self.frame.size.height-top,0) }; }

- (CGFloat)$right { return self.frame.origin.x + self.frame.size.width; }
- (void)set$right:(CGFloat)right { self.frame = (CGRect){ .origin=self.frame.origin, .size.width=fmaxf(right-self.frame.origin.x,0), .size.height=self.frame.size.height }; }

- (CGFloat)$bottom { return self.frame.origin.y + self.frame.size.height; }
- (void)set$bottom:(CGFloat)bottom { self.frame = (CGRect){ .origin=self.frame.origin, .size.width=self.frame.size.width, .size.height=fmaxf(bottom-self.frame.origin.y,0) }; }

@end
