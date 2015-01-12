//
//  vaavudFFT.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/15/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "VaavudFFT.h"
#include <Accelerate/Accelerate.h>

@interface VaavudFFT ()

- (float)pWelchWindow:(int)i;

@end

@implementation VaavudFFT {
    COMPLEX_SPLIT   A;
    FFTSetup        setupReal;
    uint32_t        log2n;
    uint32_t        n, nOver2;
    int32_t         stride;
    float           *ioData;
    float           scale;
    int             fftDataLength;
    int             fftLength;
}

- (id)initFFTLength:(int)N andFftDataLength:(int)fftDataLengthIn {
    self = [super init];
    
    if (self) {
        fftDataLength = fftDataLengthIn;
        
        fftLength = N;
        n = N;
        log2n = 0;
        
        while (N >>= 1) ++log2n;
        
        stride = 1;
        nOver2 = n / 2;
        
        //printf("1D real FFT of length log2 ( %d ) = %d\n\n", n, log2n);
        
        // Allocate memmory
        A.realp = (float *)malloc(nOver2 * sizeof(float));
        A.imagp = (float *)malloc(nOver2 * sizeof(float));
        
        ioData= (float *)malloc(n*sizeof(float));
        
        // check memmory allocation
        if (ioData == NULL || A.realp == NULL || A.imagp == NULL) {
            printf("\nmalloc failed to allocate memory for the real FFT"
                   "section of the sample.\n");
            exit(0);
        }
        
        /* Set up the required memory for the FFT routines and check  its
         * availability. */
        setupReal = vDSP_create_fftsetup(log2n, FFT_RADIX2);
        if (setupReal == NULL) {
            printf("\nFFT_Setup failed to allocate enough memory for"
                   "the real FFT.\n");
            exit(0);
        }
    }
    
    return self;
}

- (NSArray *)doFFT:(NSArray *)FFTin {
    // STEP 1 COPY DATA TO ioData, SUBTRACT MEAN, APPLY P. WELCH WINDOW, ZEROPAD
    
    double ioDataTotal = 0;
    
    for (int i = 0; i < fftDataLength; i++) {
        ioData[i] = [[FFTin objectAtIndex:i] doubleValue];
        ioDataTotal += ioData[i];
    }
    
    float ioDataMean = ioDataTotal/fftDataLength;
    
    for (int i = 0; i < fftDataLength; i++) {
        ioData[i] = (ioData[i] - ioDataMean) * [self pWelchWindow:i];
    }
    
    for (int i = fftDataLength; i < fftLength; i++) {
        ioData[i] = 0;
    }
    
    // DO THE COMPUTATION
    
    /* Look at the real signal as an interleaved complex vector  by
     * casting it.  Then call the transformation function vDSP_ctoz to
     * get a split complex vector, which for a real signal, divides into
     * an even-odd configuration. */
    vDSP_ctoz((COMPLEX *)ioData, 2, &A, 1, nOver2);
    
    /* Carry out a Forward FFT transform. */
    vDSP_fft_zrip(setupReal, &A, stride, log2n, FFT_FORWARD);
    
    /* Scale it by 2n. */
    scale = (float) 1.0 / (2 * n);
    
    vDSP_vsmul(A.realp, stride, &scale, A.realp, stride, nOver2);
    vDSP_vsmul(A.imagp, stride, &scale, A.imagp, stride, nOver2);
    
    //Zero out the nyquist value
    A.imagp[0] = 0.0;
    
    // Calculate magnitude (vector distance)
    vDSP_vdist(A.realp, stride, A.imagp, stride, ioData, 1, nOver2);
    
    // Scale again
    scale = 2;
    vDSP_vsmul(ioData, 1, &scale, ioData, 1, nOver2);

    NSMutableArray *FFTout = [NSMutableArray arrayWithCapacity:fftLength/2];
    
    for (int i = 0; i < fftLength/2; i++) {
        [FFTout insertObject:[NSNumber numberWithFloat:ioData[i]] atIndex:i];
    }
    
    return FFTout;
}

- (float)pWelchWindow:(int)i {
    float w = 1 - ((i - (fftDataLength - 1)/2) / ((fftDataLength+1)/2))^2;
    
    return w;
}

@end
