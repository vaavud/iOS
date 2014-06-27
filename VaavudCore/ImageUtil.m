//
//  ImageUtil.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 25/06/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "ImageUtil.h"

@implementation ImageUtil

+ (UIImage *)toImageFromView:(UIView*)view {
    return [self toImageFromView:view scale:0];
}

+ (UIImage *)toImageFromView:(UIView*)view scale:(CGFloat)scale {
    
    // If scale is 0, it'll follows the screen scale for creating the bounds
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, scale);

    if ([view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    }
    else {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    // Get the image out of the context
    UIImage *copied = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Return the result
    return copied;
}

@end
