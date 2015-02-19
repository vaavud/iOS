//
//  PasswordUtil.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "PasswordUtil.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation PasswordUtil

+(NSString *)createHash:(NSString *)password salt:(NSString *)salt {
    NSData *saltData = [salt dataUsingEncoding:NSUTF8StringEncoding];
    NSData *paramData = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *hash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, saltData.bytes, saltData.length, paramData.bytes, paramData.length, hash.mutableBytes);
    return [self toHexString:hash];
}

+(NSString *)toHexString:(NSData *)data {
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    
    if (!dataBuffer) {
        return nil;
    }
    
    NSUInteger dataLength = [data length];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    
    return [[NSString stringWithString:hexString] uppercaseString];
}

@end
