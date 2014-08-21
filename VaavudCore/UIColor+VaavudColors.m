//
//  UIColor+VaavudColors.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 19/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "UIColor+VaavudColors.h"

@implementation UIColor (VaavudColors)

+ (UIColor*)vaavudBlueColor {
    return [UIColor colorWithRed:(0.0/255.0) green:(174.0/255.0) blue:(239.0/255.0) alpha:1.0];
}

+ (UIColor*)vaavudRedColor {
    return [UIColor colorWithRed:(210.0/255.0) green:(37.0/255.0) blue:(45.0/255.0) alpha:1.0];
}

+ (UIColor*)vaavudAgricultureGreenColor {
    return [UIColor colorWithRed:(0.0/255.0) green:(128.0/255.0) blue:(0.0/255.0) alpha:1.0];
}

+ (UIColor*)vaavudColor {
#ifdef AGRI
    return [UIColor vaavudAgricultureGreenColor];
#elif CORE
    return [UIColor vaavudBlueColor];
#endif
}

@end
