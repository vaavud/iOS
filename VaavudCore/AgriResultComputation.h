//
//  AgriResultComputation.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 03/11/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AgriResultComputation : NSObject

+ (AgriResultComputation*) sharedInstance;

- (NSNumber *)generalConsideration:(NSNumber *)temperature windSpeed:(NSNumber *)windSpeed reduceEquipment:(NSNumber *)reduceEquipment dose:(NSNumber *)dose boomHeight:(NSNumber *)boomHeight sprayQuality:(NSNumber *)sprayQuality;

- (NSNumber *)specialConsideration:(NSNumber *)temperature windSpeed:(NSNumber *)windSpeed reduceEquipment:(NSNumber *)reduceEquipment dose:(NSNumber *)dose boomHeight:(NSNumber *)boomHeight sprayQuality:(NSNumber *)sprayQuality;

@end
