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

@implementation AlgorithmConstantsUtil

+(NSNumber*) getAlgorithm:(NSString*) model osVersion:(NSString*) version {
    switch ([AlgorithmConstantsUtil getGeneralModel:model]) {
        case IPHONE4: {
            return [NSNumber numberWithInt:ALGORITHM_IPHONE4];
        }
        default: {
            return [NSNumber numberWithInt:ALGORITHM_STANDARD];
        }
    }
}

+(NSNumber*) getAlgorithmFromString:(NSString*) algorithm {
    if ([algorithm isEqualToString:@"IPHONE4"]) {
        return [NSNumber numberWithInt:ALGORITHM_IPHONE4];
    }
    else {
        return [NSNumber numberWithInt:ALGORITHM_STANDARD];
    }
}

+(NSNumber*) getFrequencyStart:(NSString*) model osVersion:(NSString*) version {
    switch ([AlgorithmConstantsUtil getGeneralModel:model]) {
        case IPHONE4: {
            return [NSNumber numberWithDouble:I4_FREQUENCY_START];
        }
        case IPHONE5: {
            return [NSNumber numberWithDouble:I5_FREQUENCY_START];
        }
        default: {
            return [NSNumber numberWithDouble:STANDARD_FREQUENCY_START];
        }
    }
}

+(NSNumber*) getFrequencyFactor:(NSString*) model osVersion:(NSString*) version {
    switch ([AlgorithmConstantsUtil getGeneralModel:model]) {
        case IPHONE4: {
            return [NSNumber numberWithDouble:I4_FREQUENCY_FACTOR];
        }
        case IPHONE5: {
            return [NSNumber numberWithDouble:I5_FREQUENCY_FACTOR];
        }
        default: {
            return [NSNumber numberWithDouble:STANDARD_FREQUENCY_FACTOR];
        }
    }
}

+(NSNumber*) getFFTLength:(NSString*) model osVersion:(NSString*) version {
    if ([AlgorithmConstantsUtil isOSVersionGreaterThan6_1_3:version]) {
        // iOS version above 6.1.3 has a lower update frequency
        return [NSNumber numberWithInt:FQ40_FFT_LENGTH];
    }
    else {
        return [NSNumber numberWithInt:FQ60_FFT_LENGTH];
    }
}

+(NSNumber*) getFFTDataLength:(NSString*) model osVersion:(NSString*) version {
    if ([AlgorithmConstantsUtil isOSVersionGreaterThan6_1_3:version]) {
        // iOS version above 6.1.3 has a lower update frequency
        return [NSNumber numberWithInt:FQ40_FFT_DATA_LENGTH];
    }
    else {
        return [NSNumber numberWithInt:FQ60_FFT_DATA_LENGTH];
    }
}

+(int) getGeneralModel:(NSString*) model {
    NSRange charRange = NSMakeRange(0, 7);
    NSString* modelSubstring;
    if ([model length] >= 7) {
        modelSubstring = [model substringWithRange:charRange];
    }

    if ([modelSubstring isEqualToString: @"iPhone4"]) {
        return IPHONE4;
    }
    else if ([modelSubstring isEqualToString: @"iPhone5"]) {
        return IPHONE5;
    }
    else {
        return OTHER;
    }
}

+(BOOL) isOSVersionGreaterThan6_1_3:(NSString*) osVersion {
    NSComparisonResult res = [@"6.1.3" compare:osVersion];
    switch (res) {
        case NSOrderedAscending: // iOS version above 6.1.3 has a lower update frequency
            return YES;
        default:
            return NO;
    }
}

@end
