//
//  vaavudCoreController.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "AppDelegate.h"
#import "MjolnirMeasurementController.h"
#import <CoreMotion/CoreMotion.h>
#import <CoreData/CoreData.h>
#import "VaavudMagneticFieldDataManager.h"
#import "vaavudFFT.h"
#import "Property+Util.h"

@interface MjolnirMeasurementController () {}

@property (nonatomic, strong) NSMutableArray *windSpeed;
@property (nonatomic, strong) NSMutableArray *isValid;
@property (nonatomic, strong) NSMutableArray *windSpeedTime;
@property (nonatomic, strong) NSDate *startTime;

@property (nonatomic) BOOL dynamicsIsValid;
@property (nonatomic) BOOL FFTisValid;
@property (nonatomic) BOOL isValidCurrentStatus;

@property (nonatomic, strong) VaavudMagneticFieldDataManager *sharedMagneticFieldDataManager;
@property (nonatomic, strong) vaavudDynamicsController *vaavudDynamicsController;
@property (nonatomic, strong) NSArray *FFTresultx;
@property (nonatomic, strong) NSArray *FFTresulty;
@property (nonatomic, strong) NSArray *FFTresultz;
@property (nonatomic) int fftLength;
@property (nonatomic) int fftDataLength;

@property (nonatomic, strong) vaavudFFT *FFTEngine;
@property (nonatomic) int magneticFieldUpdatesCounter;
@property (nonatomic) NSInteger isValidPercent;
@property (nonatomic) BOOL iPhone4Algo;

@property (nonatomic) double sumOfValidMeasurements;
@property (nonatomic) int numberOfValidMeasurements;
@property (nonatomic) int numberOfMeasurements;
@property (nonatomic) double maxWindspeed;

@property (nonatomic) NSString *measurementSessionUUID;

@property (nonatomic) double frequencyFactor;
@property (nonatomic) double frequencyStart;

@property (nonatomic, strong) NSTimer *measuringTimer;

@end

@implementation MjolnirMeasurementController

- (id) init {
    self = [super init];
    
    if (self) {
        self.iPhone4Algo = ([[Property getAsInteger:KEY_ALGORITHM] intValue] == ALGORITHM_IPHONE4);
        self.frequencyStart = [[Property getAsDouble:KEY_FREQUENCY_START] doubleValue];
        self.frequencyFactor = [[Property getAsDouble:KEY_FREQUENCY_FACTOR] doubleValue];
        self.fftLength = [[Property getAsInteger:KEY_FFT_LENGTH] intValue];
        self.fftDataLength = [[Property getAsInteger:KEY_FFT_DATA_LENGTH] intValue];
        self.FFTEngine = [[vaavudFFT alloc] initFFTLength: self.fftLength andFftDataLength: self.fftDataLength];
        
        //NSLog(@"[VaavudCoreController] Using algorithm parameters: iPhone4Algo=%hhd, frequencyStart=%f, frequencyFactor=%f, fftLength=%d, fftDataLength=%d", self.iPhone4Algo, self.frequencyStart, self.frequencyFactor, self.fftLength, self.fftDataLength);
    }
    
    return self;
}

- (enum WindMeterDeviceType) windMeterDeviceType {
    return MjolnirWindMeterDeviceType;
}

- (void) start {
    
    self.dynamicsIsValid = NO;
    self.isValidPercent = 50; // start at 50% valid
    self.isValidCurrentStatus = NO;
    
    self.startTime = [NSDate date];
    self.windSpeed = [NSMutableArray arrayWithCapacity:1000];
    self.windSpeedTime = [NSMutableArray arrayWithCapacity:1000];
    self.isValid = [NSMutableArray arrayWithCapacity:1000];
    self.magneticFieldUpdatesCounter = 0;
    self.numberOfValidMeasurements = 0;
    self.sumOfValidMeasurements = 0;
    
    // create reference to MagneticField Data Manager and start
    self.sharedMagneticFieldDataManager = [VaavudMagneticFieldDataManager sharedMagneticFieldDataManager];
    self.sharedMagneticFieldDataManager.delegate = self;
    [self.sharedMagneticFieldDataManager start];
    
    // create dynamics controller and start
    self.vaavudDynamicsController = [[vaavudDynamicsController alloc] init];
    self.vaavudDynamicsController.vaavudCoreController = self;
    [self.vaavudDynamicsController start];
    
    self.measuringTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(pushValuesToDelegate) userInfo:nil repeats:YES];
    
    if ([self.delegate respondsToSelector:@selector(changedValidity:dynamicsIsValid:)]) {
        [self.delegate changedValidity:self.isValidCurrentStatus dynamicsIsValid:self.dynamicsIsValid];
    }
}

- (NSTimeInterval) stop {
        
    if (self.measuringTimer) {
        [self.measuringTimer invalidate];
        self.measuringTimer = nil;
    }

    [self.sharedMagneticFieldDataManager stop];
    [self.vaavudDynamicsController stop];

    return [[NSDate date] timeIntervalSinceDate:self.startTime];
}

- (void) pushValuesToDelegate {
    if (self.delegate && self.isValidCurrentStatus) {
        
        NSNumber *currentSpeed = [self.windSpeed lastObject];
        NSNumber *avgSpeed = [self getAverage];
        NSNumber *maxSpeed = [self getMax];

        [self.delegate addSpeedMeasurement:currentSpeed avgSpeed:avgSpeed maxSpeed:maxSpeed];
    }
}

- (void) remove {
}

- (void) updateIsValid {
    
    BOOL wasValid = self.isValidCurrentStatus;
    
    if (!self.FFTisValid) {
        self.isValidPercent = 0;
    }
    
    if (self.FFTisValid && self.dynamicsIsValid) {
        self.isValidPercent += 8;
    } else {
        self.isValidPercent -= 8;
    }
    
    if (self.isValidPercent > 100) {
        self.isValidPercent = 100;
        self.isValidCurrentStatus = YES;
    }
    
    if (self.isValidPercent < 0) {
        self.isValidPercent = 0;
        self.isValidCurrentStatus = NO;
    }
    
    [self.isValid addObject:[NSNumber numberWithBool:self.isValidCurrentStatus]];

    if (wasValid != self.isValidCurrentStatus) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(changedValidity:dynamicsIsValid:)]) {
            [self.delegate changedValidity:self.isValidCurrentStatus dynamicsIsValid:self.dynamicsIsValid];
        }
    }
}

- (void) DynamicsIsValid:(BOOL)validity {
    if (self.dynamicsIsValid != validity) {
        self.dynamicsIsValid = validity;

        if (self.delegate && [self.delegate respondsToSelector:@selector(changedValidity:dynamicsIsValid:)]) {
            [self.delegate changedValidity:self.isValidCurrentStatus dynamicsIsValid:self.dynamicsIsValid];
        }
    }
}

- (void) newHeading:(NSNumber*)newHeading {

}

- (void) magneticFieldValuesUpdated {
    
    self.magneticFieldUpdatesCounter += 1;
    
    if (self.magneticFieldUpdatesCounter > self.fftDataLength){
        
        bool runAnalysis;
        NSMutableArray *FFTaverage;
        
        if (self.iPhone4Algo) {
            if (self.magneticFieldUpdatesCounter % 12 == 0) {
                runAnalysis = YES;
            }
            else {
                runAnalysis = NO;
            }
                
        }
        else {
            if (self.magneticFieldUpdatesCounter % 3 == 0) {
                runAnalysis = YES;
            }
            else {
                runAnalysis = NO;
            }
        }
        
        if ( runAnalysis ) {
            
            if (self.iPhone4Algo) {
             
                NSRange subArrayRange = NSMakeRange(self.magneticFieldUpdatesCounter - self.fftDataLength, self.fftDataLength);
                
                    self.FFTresulty = [self.FFTEngine doFFT: [self.sharedMagneticFieldDataManager.magneticFieldReadingsy subarrayWithRange:subArrayRange]];
                    self.FFTresultz = [self.FFTEngine doFFT: [self.sharedMagneticFieldDataManager.magneticFieldReadingsz subarrayWithRange:subArrayRange]];
                
                // create average
                int resultArrayLength = self.fftLength/2;
                
                
                FFTaverage = [NSMutableArray arrayWithCapacity: resultArrayLength];
                
                for (int i = 0; i < resultArrayLength; i++) {
                    
                    double mean = ( [[self.FFTresulty objectAtIndex:i ] doubleValue] + [[self.FFTresultz objectAtIndex:i ] doubleValue] ) / 2;
                    
                    [FFTaverage insertObject:[NSNumber numberWithDouble: mean] atIndex: i];
                }

                
                
            }
            else {
                
                int modulus = self.magneticFieldUpdatesCounter % 9 / 3;
                
                NSRange subArrayRange = NSMakeRange(self.magneticFieldUpdatesCounter - self.fftDataLength, self.fftDataLength);
                
                switch (modulus) {
                    case 0:
                        self.FFTresultx = [self.FFTEngine doFFT: [self.sharedMagneticFieldDataManager.magneticFieldReadingsx subarrayWithRange:subArrayRange]];
                        break;
                    case 1:
                        self.FFTresulty = [self.FFTEngine doFFT: [self.sharedMagneticFieldDataManager.magneticFieldReadingsy subarrayWithRange:subArrayRange]];
                        break;
                    case 2:
                        self.FFTresultz = [self.FFTEngine doFFT: [self.sharedMagneticFieldDataManager.magneticFieldReadingsz subarrayWithRange:subArrayRange]];
                        break;
                        
                    default:
                        NSLog(@"You should not be here!");
                        break;
                }
                
                // create average
                int resultArrayLength = self.fftLength/2;
                
                
                FFTaverage = [NSMutableArray arrayWithCapacity: resultArrayLength];
                
                for (int i = 0; i < resultArrayLength; i++) {
                    
                    double mean = ( [[self.FFTresultx objectAtIndex:i ] doubleValue] + [[self.FFTresulty objectAtIndex:i ] doubleValue] + [[self.FFTresultz objectAtIndex:i ] doubleValue] ) / 3;
                    
                    [FFTaverage insertObject:[NSNumber numberWithDouble: mean] atIndex: i];
                }
            }
            
            // calculate actual sample frequency
            
            double actualSampleFrequency = [[self getSampleFrequency] doubleValue];
            
            // use quadratic interpolation to find peak
            // Calculate max peak
            double maxPeak = 0;
            double alpha, beta, gamma, p, dominantFrequency, frequencyMagnitude;
            
            int maxBin = 0;
            
            for (int i=0; i<self.fftLength/2; i++) {
                
                if ([[FFTaverage objectAtIndex:i] doubleValue] > maxPeak){
                    maxBin = i;
                    maxPeak = [[FFTaverage objectAtIndex:i] doubleValue];
                }
            }
            
            if ((maxBin > 0) && (maxBin < self.fftLength/2 -1)) {
                alpha = [[FFTaverage objectAtIndex: maxBin-1 ] doubleValue];
                beta = [[FFTaverage objectAtIndex: maxBin ] doubleValue];
                gamma = [[FFTaverage objectAtIndex: maxBin+1 ] doubleValue];
                
                p = (alpha - gamma) / (2*(alpha - 2*beta + gamma));
                
                dominantFrequency  = (maxBin+p)*actualSampleFrequency/self.fftLength;
                frequencyMagnitude = beta - 1/4 * (alpha - gamma) * p;
                
            } else {
                dominantFrequency = 0;
                frequencyMagnitude = 0;
            }
            
            // windspeed
            
            double windspeed = [self  convertFrequencyToWindspeed: dominantFrequency];
            
            [self.windSpeed addObject: [NSNumber numberWithDouble: windspeed]];
            [self.windSpeedTime addObject: [self.sharedMagneticFieldDataManager.magneticFieldReadingsTime lastObject]];
            
            
            if (frequencyMagnitude > FFTpeakMagnitudeMinForValid) {
                self.FFTisValid = YES;
                
                self.sumOfValidMeasurements += windspeed;
                self.numberOfValidMeasurements ++;
                if (windspeed > self.maxWindspeed)
                    self.maxWindspeed = windspeed;
            }
            else {
                self.FFTisValid = NO;
                // TODO: reinsert
                //NSLog(@"FFTpeakMagnetude too low - value: @%f", frequencyMagnitude);
            }
            
            self.numberOfMeasurements++;
            [self updateIsValid];
        } // run every X update
    } // if counter > datalength
}

- (NSNumber*) getSampleFrequency {
    
    double timedifference = [[self.sharedMagneticFieldDataManager.magneticFieldReadingsTime lastObject] doubleValue];
    
    NSNumber *sampleFrequency = [NSNumber numberWithDouble:(double) (self.magneticFieldUpdatesCounter-1) / timedifference];
    //NSLog(@"freq=%@", n);
    return sampleFrequency;
}


- (NSNumber*) getAverage {
    return [NSNumber numberWithDouble:self.sumOfValidMeasurements / self.numberOfValidMeasurements];
}

- (NSNumber*) getMax {
    return [NSNumber numberWithDouble:self.maxWindspeed];
}

- (double) convertFrequencyToWindspeed: (double) frequency {
    
    // Based on 09.07.2013 Windtunnel test. Parametes can be found in windTunnelAnalysis_9_07_2013.xlsx
    // Corrected base on data from Windtunnel test Experiment26Aug2013Data.xlsx
    double windspeed;
    
    windspeed = self.frequencyFactor * frequency + self.frequencyStart;
    
    if (frequency > 17.65 && frequency < 28.87) {
        windspeed = windspeed + -0.068387 * pow((frequency - 23.2667), 2) + 2.153493;
    } 
    
    return windspeed;
}

@end
