//
//  UUIDUtil.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 28/06/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "UUIDUtil.h"

@implementation UUIDUtil // fixme: remove?

+ (NSString *)generateUUID {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge_transfer NSString *)string;
}

+ (NSString *)md5Hash:(NSString *)text {
    const char *ptr = [text UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    if (strlen(ptr) > UINT32_MAX) {
        return nil;
    }
    
    CC_MD5(ptr, (UInt32) strlen(ptr), md5Buffer);
        
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", md5Buffer[i]];
    }
    
    return [output uppercaseString];
}

@end
