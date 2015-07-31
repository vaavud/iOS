//
//  UIImage+Vaavud.m
//  Vaavud
//
//  Created by Gustaf Kugelberg on 31/07/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

#import "UIImage+Vaavud.h"

@implementation UIImage (Vaavud)

+(UIImage *)imageWithColor:(UIColor *)color forSize:(CGSize)size {
    return [self imageWithColor:color forSize:size withCornerRadius:0];
}

+(UIImage *)imageWithColor:(UIColor *)color forSize:(CGSize)size withCornerRadius:(CGFloat)radius {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Begin a new image that will be the new image with the rounded corners
    // (here with the size of an UIImageView)
    UIGraphicsBeginImageContext(size);
    
    // Add a clip before drawing anything, in the shape of an rounded rect
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius] addClip];
    // Draw your image
    [image drawInRect:rect];
    
    // Get the image, here setting the UIImageView image
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    // Lets forget about that we were drawing
    UIGraphicsEndImageContext();
    
    return image;
}

@end
