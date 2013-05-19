//
//  Constants.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#define preferedSampleFrequency 100
#define accAndGyroSampleFrequency 5
#define FFTLength 64
#define FFTDataLength 40
#define FFTForEvery 3

// Thresholds for isValid
#define accelerationMaxForValid 0.1 // g acc/(9.82 m/s^2)
#define angularVelocityMaxForValid 0.4 // rad/s (maybe deg/s or another unit)
#define orientationDeviationMaxForValid 0.17 // rad  (10) degrees
#define FFTpeakMagnitudeMinForValid 8 // (abs(FFT(maxbin))
