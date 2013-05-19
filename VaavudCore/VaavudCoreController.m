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
@property (nonatomic, strong) NSArray *FFTresultx;
@property (nonatomic, strong) NSArray *FFTresulty;
@property (nonatomic, strong) NSArray *FFTresultz;
//@property (nonatomic, strong) NSMutableArray *FFTresultAverage;
@property (nonatomic, strong) vaavudFFT *FFTEngine;
@property (nonatomic) int magneticFieldUpdatesCounter;
@property (nonatomic) BOOL dynamicsIsValid;
@property (nonatomic) BOOL FFTisValid;
@property (nonatomic) NSUInteger isValidCounter;

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
        self.dynamicsIsValid = NO;
        self.isValidCounter = 0;

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
    
    
    
}

- (void) stop
{
    [self.sharedMagneticFieldDataManager stop];
}


- (void) remove
{
    
}

- (void) updateIsValid{
    
    self.isValidCounter++;
    
    BOOL validity = [[self.isValid lastObject] boolValue];
    
    if (self.isValidCounter > 20){
        
        if (self.FFTisValid && self.dynamicsIsValid) {
            validity = YES;
        } else {
            validity = NO;
        }
        
        if (validity != [[self.isValid lastObject] boolValue])
            self.isValidCounter = 0;
        
    }

    [self.isValid addObject: [NSNumber numberWithBool: validity]];
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
                
                dominantFrequency  = (maxBin+p)*preferedSampleFrequency/FFTLength;   ///!!! SHOULD USE ACTUAL SAMPLE FREQUENCY
                frequencyMagnitude = beta - 1/4 * (alpha - gamma) * p;
                
            } else {
                dominantFrequency = 0;
                frequencyMagnitude = 0;
            }
            
            
            
            [self.windSpeed addObject: [NSNumber numberWithDouble: dominantFrequency]];
            [self.time addObject: [self.sharedMagneticFieldDataManager.magneticFieldReadingsTime lastObject]];
            
            
            if (frequencyMagnitude > FFTpeakMagnitudeMinForValid)
                self.FFTisValid = YES;
            else
                self.FFTisValid = NO;
            
            [self updateIsValid];
                        
            
        } // run every X update
    } // if counter > datalength
}


@end
