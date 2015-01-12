//
//  ImageUtil.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 25/06/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageUtil : NSObject

+ (UIImage *)toImageFromView:(UIView *)view;
+ (UIImage *)toImageFromView:(UIView *)view scale:(CGFloat)scale;
+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size;

@end
