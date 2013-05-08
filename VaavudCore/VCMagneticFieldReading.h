//
//  VCMagneticFieldReading.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VCMagneticFieldReading : NSObject

@property (readonly, nonatomic) double time;
@property (readonly, nonatomic) double x;
@property (readonly, nonatomic) double y;
@property (readonly, nonatomic) double z;

- (id) initWithTime: (double) time timeAndX: (double) x andY: (double) y andZ: (double) z;

@end
