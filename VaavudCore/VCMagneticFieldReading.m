//
//  VCMagneticFieldReading.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "VCMagneticFieldReading.h"

@interface VCMagneticFieldReading ()

@property (nonatomic) double time;
@property (nonatomic) double x;
@property (nonatomic) double y;
@property (nonatomic) double z;

@end

@implementation VCMagneticFieldReading

- (id) initWithTime:(double)time timeAndX:(double)x andY:(double)y andZ:(double)z {
    
    self = [super init];
    
    if (self)
    {
        // Do initializing
        self.time = time;
        self.x = x;
        self.y = y;
        self.z = z;
        
    }
    
    return self;
}

@end
