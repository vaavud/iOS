//
//  UIColor+VaavudColors.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 19/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "UIColor+VaavudColors.h"

@implementation UIColor (VaavudColors)

+ (UIColor *)vaavudBlueColor {
    return [UIColor colorWithRed:(0.0/255.0) green:(174.0/255.0) blue:(239.0/255.0) alpha:1.0];
}

+ (UIColor *)vaavudRedColor {
    return [UIColor colorWithRed:(210.0/255.0) green:(37.0/255.0) blue:(45.0/255.0) alpha:1.0];
}

+ (UIColor *)vaavudGreenColor {
    return [UIColor colorWithRed:(108.0/255.0) green:(192.0/255.0) blue:(73.0/255.0) alpha:1.0];
}

+ (UIColor *)vaavudGreyColor {
    return [UIColor colorWithRed:(213.0/255.0) green:(213.0/255.0) blue:(213.0/255.0) alpha:1.0];
}


+ (UIColor *)vaavudColor {
#ifdef AGRI
    return [UIColor vaavudGreenColor];
#elif CORE
    return [UIColor vaavudBlueColor];
#endif
}

@end
