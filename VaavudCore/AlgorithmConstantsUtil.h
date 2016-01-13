//
//  AlgorithmConstantsUtil.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 17/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlgorithmConstantsUtil : NSObject

+ (double)getFrequencyFactor:(NSString *)model;
+ (double)getFFTMagMin:(NSString *)model;

@end
