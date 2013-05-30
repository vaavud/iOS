//
//  vaavudCoreController.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "VaavudCoreController.h"
#import <CoreMotion/CoreMotion.h>
#import "VaavudMagneticFieldDataManager.h"
#import "vaavudFFT.h"

@interface VaavudCoreController () {
    
}

// public properties - create setters
@property (nonatomic) float currentWindSpeed;
@property (nonatomic) float currentWindDirection;
@property (nonatomic) float currentWindSpeedMax;
@property (nonatomic, strong) NSMutableArray *windSpeed;
@property (nonatomic, strong) NSMutableArray *isValid;
@property (nonatomic, strong) NSMutableArray *time;

 // private properties
@property (nonatomic, strong) VaavudMagneticFieldDataManager *sharedMagneticFieldDataManager;
@property (nonatomic, strong) vaavudDynamicsController *vaavudDynamicsController;
@property (nonatomic, strong) NSArray *FFTresultx;
@property (nonatomic, strong) NSArray *FFTresulty;
@property (nonatomic, strong) NSArray *FFTresultz;
//@property (nonatomic, strong) NSMutableArray *FFTresultAverage;
@property (nonatomic, strong) vaavudFFT *FFTEngine;
@property (nonatomic) int magneticFieldUpdatesCounter;
@property (nonatomic) NSInteger isValidPercent;
@property (nonatomic) BOOL isValidCurrentStatus;

@property (nonatomic) double    sumOfValidMeasurements;
@property (nonatomic) int       numberOfValidMeasurements;
@property (nonatomic) int       numberOfMeasurements;
@property (nonatomic) double    maxWindspeed;

- (void) updateIsValid;

@end


@implementation VaavudCoreController 

// Public methods

- (id) init
{
    self = [super init];
    
    if (self)
    {
        // Do initializing
        self.FFTEngine = [[vaavudFFT alloc] initFFTLength:FFTLength];
        self.dynamicsIsValid = YES;
        self.isValidPercent = 50; // start at 2% valid
        self.isValidCurrentStatus = YES;

    }
    
    return self;
    
}

- (void) start
{

    // create reference to MagneticField Data Manager
    self.sharedMagneticFieldDataManager = [VaavudMagneticFieldDataManager sharedMagneticFieldDataManager];
    self.sharedMagneticFieldDataManager.delegate = self;
    self.magneticFieldUpdatesCounter = 0;
    
    self.windSpeed = [NSMutableArray arrayWithCapacity:1000];
    self.time = [NSMutableArray arrayWithCapacity:1000];
    self.isValid = [NSMutableArray arrayWithCapacity:1000];
    [self.sharedMagneticFieldDataManager start];
    
    self.vaavudDynamicsController = [[vaavudDynamicsController alloc] init];
    self.vaavudDynamicsController.delegate = self;
    [self.vaavudDynamicsController start];
    
    self.numberOfValidMeasurements = 0;
    self.sumOfValidMeasurements = 0;
    
}

- (void) stop
{
    [self.sharedMagneticFieldDataManager stop];
    [self.vaavudDynamicsController stop];
}


- (void) remove
{
    
}

- (void) updateIsValid{
    
    if (!self.FFTisValid) {
        self.isValidPercent =0;
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
    
    
    [self.isValid addObject: [NSNumber numberWithBool: self.isValidCurrentStatus]];


}

// protocol method
- (void) DynamicsIsValid: (BOOL) validity
{
    self.dynamicsIsValid = validity;
}


// protocol method
- (void) magneticFieldValuesUpdated
{
    self.magneticFieldUpdatesCounter += 1;
    
    if (self.magneticFieldUpdatesCounter > FFTDataLength){
        
        if ( self.magneticFieldUpdatesCounter % 3 == 0 ) {
            
            int modulus = self.magneticFieldUpdatesCounter % 9 / 3;
            
            NSRange subArrayRange = NSMakeRange(self.magneticFieldUpdatesCounter - FFTDataLength, FFTDataLength);
            
            switch (modulus) {
                case 0:
                    self.FFTresultx = [self.FFTEngine doFFT: [self.sharedMagneticFieldDataManager.magneticFieldReadingsx subarrayWithRange:subArrayRange]];
                    break;
                case 1:
                    self.FFTresulty = [self.FFTEngine doFFT: [self.sharedMagneticFieldDataManager.magneticFieldReadingsy subarrayWithRange:subArrayRange]];
                    break;
                case 2:
                    self.FFTresultz
                    = [self.FFTEngine doFFT: [self.sharedMagneticFieldDataManager.magneticFieldReadingsz subarrayWithRange:subArrayRange]];
                    break;
                    
                default:
                    NSLog(@"You should not be here!");
                    break;
            }
            
            // create average
            int resultArrayLength = FFTLength/2;
            
            
            NSMutableArray *FFTaverage = [NSMutableArray arrayWithCapacity: resultArrayLength];
            
            for (int i = 0; i < resultArrayLength; i++) {
                
                double mean = ( [[self.FFTresultx objectAtIndex:i ] doubleValue] + [[self.FFTresulty objectAtIndex:i ] doubleValue] + [[self.FFTresultz objectAtIndex:i ] doubleValue] ) / 3;
                
                [FFTaverage insertObject:[NSNumber numberWithDouble: mean] atIndex: i];
            }
            
            
            // calculate actual sample frequency
            
            NSArray *timeSeries = [self.sharedMagneticFieldDataManager.magneticFieldReadingsTime subarrayWithRange: subArrayRange];
            
            double timeDifference = [[timeSeries lastObject] doubleValue] - [[timeSeries objectAtIndex:0] doubleValue];
            
            double actualSampleFrequency = (FFTDataLength-1)/timeDifference;
            
            // use quadratic interpolation to find peak
            // Calculate max peak
            double maxPeak = 0;
            double alpha, beta, gamma, p, dominantFrequency, frequencyMagnitude;
            
            int maxBin = 0;
            
            for (int i=0; i<FFTLength/2; i++) {
                
                if ([[FFTaverage objectAtIndex:i] doubleValue] > maxPeak){
                    maxBin = i;
                    maxPeak = [[FFTaverage objectAtIndex:i] doubleValue];
                }
            }
            
            if ((maxBin > 0) && (maxBin < FFTLength/2 -1)) {
                alpha = [[FFTaverage objectAtIndex: maxBin-1 ] doubleValue];
                beta = [[FFTaverage objectAtIndex: maxBin ] doubleValue];
                gamma = [[FFTaverage objectAtIndex: maxBin+1 ] doubleValue];
                
                p = (alpha - gamma) / (2*(alpha - 2*beta + gamma));
                
                dominantFrequency  = (maxBin+p)*actualSampleFrequency/FFTLength;
                frequencyMagnitude = beta - 1/4 * (alpha - gamma) * p;
                
            } else {
                dominantFrequency = 0;
                frequencyMagnitude = 0;
            }
            
            
            
            [self.windSpeed addObject: [NSNumber numberWithDouble: dominantFrequency]];
            [self.time addObject: [self.sharedMagneticFieldDataManager.magneticFieldReadingsTime lastObject]];
            
            
            if (frequencyMagnitude > FFTpeakMagnitudeMinForValid) {
                self.FFTisValid = YES;
                
                self.sumOfValidMeasurements += dominantFrequency;
                self.numberOfValidMeasurements ++;
                if (dominantFrequency > self.maxWindspeed)
                    self.maxWindspeed = dominantFrequency;
            }
            else {
                self.FFTisValid = NO;
                NSLog(@"FFTpeakMagnetude too low - value: @%f", frequencyMagnitude);
            }
            
            self.numberOfMeasurements++;
            [self updateIsValid];
                        
            
        } // run every X update
    } // if counter > datalength
}

- (NSNumber *) getAverage
{
    return [NSNumber numberWithDouble: self.sumOfValidMeasurements/self.numberOfValidMeasurements];
}
- (NSNumber *) getMax
{
    return [NSNumber numberWithDouble: self.maxWindspeed];
}

- (NSNumber *) getProgress
{
    
    float elapsedTime = [[self.time lastObject] floatValue];
    float measurementFrequency = self.numberOfMeasurements/elapsedTime;
    float validTime = self.numberOfValidMeasurements / measurementFrequency;

    
    double progress = validTime/minimumNumberOfSeconds;
    if (progress > 1)
        progress = 1;
    
    return [NSNumber numberWithDouble: progress];
}


@end
