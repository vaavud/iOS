//
//  AlgorithmConstantsUtil.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 17/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlgorithmConstantsUtil : NSObject

+ (NSNumber *)getAlgorithm:(NSString *)model osVersion:(NSString *)version;
+ (NSNumber *)getAlgorithmFromString:(NSString *)algorithm;
+ (NSNumber *)getFrequencyStart:(NSString *)model osVersion:(NSString *)version;
+ (NSNumber *)getFrequencyFactor:(NSString *)model osVersion:(NSString *)version;
+ (NSNumber *)getFFTLength:(NSString *)model osVersion:(NSString *)version;
+ (NSNumber *)getFFTDataLength:(NSString *)model osVersion:(NSString *)version;
+ (NSNumber *)getFFTMagMin:(NSString *)model osVersion:(NSString *)version;

@end
