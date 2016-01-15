//
//  Constants.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#define LOG_INTRO NO
#define LOG_NETWORK NO
#define LOG_ACCOUNT NO
#define LOG_GRAPH NO
#define LOG_LOCATION NO
#define LOG_HISTORY NO
#define LOG_MODEL NO
#define LOG_UPLOAD NO
#define LOG_SLEIPNIR NO
#define LOG_OTHER NO

#define APP "Vaavud"

#define preferedSampleFrequency 100 // actual is arround 63 
#define accAndGyroSampleFrequency 5
#define FFTForEvery 3

// Thresholds for isValid
#define accelerationMaxForValid 0.4 // g acc/(9.82 m/s^2)
#define angularVelocityMaxForValid 0.4 // rad/s (maybe deg/s or another unit)
#define orientationDeviationMaxForValid 0.63 // rad  (36) degrees

#define KELVIN_TO_CELCIUS 273.15

#define BUTTON_CORNER_RADIUS 4
#define FORM_CORNER_RADIUS 4
#define DIALOG_CORNER_RADIUS 6

static double const STANDARD_FREQUENCY_START = 0.238;

static double const STANDARD_FREQUENCY_FACTOR = 1.07;
static double const I4_FREQUENCY_FACTOR = 1.16;
static double const I5_FREQUENCY_FACTOR = 1.04;

static int const FQ40_FFT_LENGTH = 64;
static int const FQ40_FFT_DATA_LENGTH = 50;

static double const FFT_PEAK_MAG_MIN_GENERAL = 5.0;
static double const FFT_PEAK_MAG_MIN_IPHONE6 = 2.5;

static NSString * const GOOGLE_STATIC_MAPS_API_KEY = @"AIzaSyDrrZsMKRBkCw214SbJA6q2lO-cXbu7m0Y";

static NSString * const KEY_STORED_LOCATION_LAT = @"storedLocationLat";
static NSString * const KEY_STORED_LOCATION_LON = @"storedLocationLon";

//static NSString * const vaavudAPIBaseURLString = @"http://10.0.5.70:8080";
static NSString * const vaavudAPIBaseURLString = @"https://mobile-api.vaavud.com/";
