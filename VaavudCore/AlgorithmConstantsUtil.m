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

+ (double)getFrequencyFactor:(NSString *)model {
    switch ([AlgorithmConstantsUtil getGeneralModel:model]) {
        case IPHONE4:
            return I4_FREQUENCY_FACTOR;
        case IPHONE5:
        case IPHONE6:
            return I5_FREQUENCY_FACTOR;
        default:
            return STANDARD_FREQUENCY_FACTOR;
    }
}

+ (double)getFFTMagMin:(NSString *)model {
    switch ([AlgorithmConstantsUtil getGeneralModel:model]) {
        case IPHONE6:
            return FFT_PEAK_MAG_MIN_IPHONE6;
        default:
            return FFT_PEAK_MAG_MIN_GENERAL;
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

@end
