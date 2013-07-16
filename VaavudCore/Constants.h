//
//  Constants.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#define APP "Vaavud"

#define preferedSampleFrequency 100 // actual is arround 63 
#define accAndGyroSampleFrequency 5
#define FFTLength 64
#define FFTDataLength 40
#define FFTForEvery 3

// Thresholds for isValid
#define accelerationMaxForValid 0.1 // g acc/(9.82 m/s^2)
#define angularVelocityMaxForValid 0.4 // rad/s (maybe deg/s or another unit)
#define orientationDeviationMaxForValid 0.63 // rad  (36) degrees
#define FFTpeakMagnitudeMinForValid 5 // (abs(FFT(maxbin))

// Threshold for valid measurement
#define minimumNumberOfSeconds 30

// Only save every Nth measurement point - set to 1 to save all
#define saveEveryNthPoint 10

//static NSString * const vaavudAPIBaseURLString = @"http://192.168.0.105:8080/";
//static NSString * const vaavudAPIBaseURLString = @"http://10.117.1.32:8080/";
static NSString * const vaavudAPIBaseURLString = @"https://mobile-api.vaavud.com/";
