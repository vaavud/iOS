//
//  MeasurementPoint.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 27/06/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MeasurementSession;

@interface MeasurementPoint : NSManagedObject

@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSNumber * windDirection;
@property (nonatomic, retain) NSNumber * windSpeed;
@property (nonatomic, retain) MeasurementSession *session;

@end
