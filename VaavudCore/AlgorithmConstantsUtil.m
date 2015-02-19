//
//  AlgorithmConstantsUtil.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 17/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "AlgorithmConstantsUtil.h"

static int const OTHER = 0;
static int const IPHONE4 = 1;
static int const IPHONE5 = 2;
static int const IPHONE6 = 3;

@implementation AlgorithmConstantsUtil

+ (NSNumber *)getAlgorithm:(NSString *)model osVersion:(NSString *)version {
    switch ([AlgorithmConstantsUtil getGeneralModel:model]) {
        case IPHONE4:
            return @(ALGORITHM_IPHONE4);
        default:
            return @(ALGORITHM_STANDARD);
    }
}

+ (NSNumber *)getAlgorithmFromString:(NSString *)algorithm {
    if ([algorithm isEqualToString:@"IPHONE4"]) {
        return @(ALGORITHM_IPHONE4);
    }
    else {
        return @(ALGORITHM_STANDARD);
    }
}

+ (NSNumber *)getFrequencyStart:(NSString *)model osVersion:(NSString *)version {
    switch ([AlgorithmConstantsUtil getGeneralModel:model]) {
        case IPHONE4:
            return @(I4_FREQUENCY_START);
        case IPHONE5:
            return @(I5_FREQUENCY_START);
        default:
            return @(STANDARD_FREQUENCY_START);
    }
}

+ (NSNumber *)getFrequencyFactor:(NSString *)model osVersion:(NSString *)version {
    switch ([AlgorithmConstantsUtil getGeneralModel:model]) {
        case IPHONE4:
            return @(I4_FREQUENCY_FACTOR);
        case IPHONE5:
            return @(I5_FREQUENCY_FACTOR);
        default:
            return @(STANDARD_FREQUENCY_FACTOR);
    }
}

+ (NSNumber *)getFFTLength:(NSString *)model osVersion:(NSString *)version {
    if ([AlgorithmConstantsUtil isOSVersionGreaterThan6_1_3:version]) {
        // iOS version above 6.1.3 has a lower update frequency
        return @(FQ40_FFT_LENGTH);
    }
    else {
        return @(FQ60_FFT_LENGTH);
    }
}

+ (NSNumber *)getFFTDataLength:(NSString *)model osVersion:(NSString *)version {
    if ([AlgorithmConstantsUtil isOSVersionGreaterThan6_1_3:version]) {
        // iOS version above 6.1.3 has a lower update frequency
        return @(FQ40_FFT_DATA_LENGTH);
    }
    else {
        return @(FQ60_FFT_DATA_LENGTH);
    }
}

+ (NSNumber *)getFFTMagMin:(NSString *)model osVersion:(NSString *)version {
    switch ([AlgorithmConstantsUtil getGeneralModel:model]) {
        case IPHONE6:
            return @(FFT_PEAK_MAG_MIN_IPHONE6);
        default:
            return @(FFT_PEAK_MAG_MIN_GENERAL);
    }
}

+ (int)getGeneralModel:(NSString *)model {
    if ([model isEqual:@"iPhone3,1"]) return IPHONE4;       // iPhone 4 (GSM)
    if ([model isEqual:@"iPhone3,2"]) return IPHONE4;       // iPhone 4 (GMS Rev A)
    if ([model isEqual:@"iPhone3,3"]) return IPHONE4;       // iPhone 4 (GSM + CDMA)
    if ([model isEqual:@"iPhone4,1"]) return IPHONE4;       // iPhone 4S
    if ([model isEqual:@"iPhone5,1"]) return IPHONE5;       // iPhone 5 (GSM)
    if ([model isEqual:@"iPhone5,2"]) return IPHONE5;       // iPhone 5 (GSM + CDMA)
    if ([model isEqual:@"iPhone5,3"]) return IPHONE5;       // iPhone 5c
    if ([model isEqual:@"iPhone5,4"]) return IPHONE5;       // iPhone 5c
    if ([model isEqual:@"iPhone6,1"]) return IPHONE5;       // iPhone 5s
    if ([model isEqual:@"iPhone6,2"]) return IPHONE5;       // iPhone 5s
    if ([model isEqual:@"iPhone7,1"]) return IPHONE6;       // iPhone 6
    if ([model isEqual:@"iPhone7,2"]) return IPHONE6;       // iPhone 6+
    
    return OTHER;
}

+ (BOOL)isOSVersionGreaterThan6_1_3:(NSString *)osVersion {
    // iOS version above 6.1.3 has a lower update frequency
    return [@"6.1.3" compare:osVersion] == NSOrderedAscending;
}

@end
