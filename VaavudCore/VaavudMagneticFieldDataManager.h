//
//  VaavudMagneticFieldDataManager.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/9/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VaavudMagneticFieldDataManager;             //define class, so protocol can see VaavudMagneticFieldDataManager
@protocol VaavudMagneticFieldDataManagerDelegate   //define delegate protocol
- (void) magneticFieldValuesUpdated;               //define delegate method to be implemented within another class
@end //end protocol


@interface VaavudMagneticFieldDataManager : NSObject

+ (VaavudMagneticFieldDataManager*) sharedMagneticFieldDataManager;

- (void) start;
- (void) stop;

@property (readonly, nonatomic, strong) NSMutableArray *magneticFieldReadings;

@property (nonatomic, weak) id <VaavudMagneticFieldDataManagerDelegate> delegate; //define MyClassDelegate as delegate

@end
