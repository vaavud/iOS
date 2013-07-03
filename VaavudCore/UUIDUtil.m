//
//  UUIDUtil.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 28/06/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "UUIDUtil.h"

@implementation UUIDUtil

+ (NSString *) generateUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    return (__bridge_transfer NSString *)string;
}

@end
