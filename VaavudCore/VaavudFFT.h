//
//  VaavudFFT.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/15/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VaavudFFT : NSObject

- (id)initFFTLength:(int)N andFftDataLength:(int)fftDataLengthIn;

- (NSArray *)doFFT:(NSArray *)FFTin;

@end
