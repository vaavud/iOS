//
//  Constants.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#define preferedSampleFrequency 60
#define accAndGyroSampleFrequency 5
#define FFTLength 64
#define FFTDataLength 40
#define FFTForEvery 3

// Thresholds for isValid
#define accelerationMaxForValid 0.1 // m/s^2
#define angularVelocityMaxForValid 0.1 // rad/s
#define orientationDeviationMaxForValid 15 // degrees
#define FFTpeakMagnitudeMinForValid 8 // (abs(FFT(maxbin))
