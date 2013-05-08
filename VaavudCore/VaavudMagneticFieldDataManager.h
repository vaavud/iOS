//
//  VaavudMagneticFieldDataManager.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/9/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VaavudMagneticFieldDataManager : NSObject

+ (VaavudMagneticFieldDataManager*) sharedMagneticFieldDataManager;

- (void) start;
- (void) stop;

@property (readonly, nonatomic, strong) NSMutableArray *magneticFieldReadings;


@end
