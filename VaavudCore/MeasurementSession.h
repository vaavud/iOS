//
//  MeasurementSession.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 29/10/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MeasurementPoint;

@interface MeasurementSession : NSManagedObject

@property (nonatomic, retain) NSNumber * boomHeight;
@property (nonatomic, retain) NSString * device;
@property (nonatomic, retain) NSNumber * dose;
@property (nonatomic, retain) NSNumber * endIndex;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSNumber * generalConsideration;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * measuring;
@property (nonatomic, retain) NSNumber * reducingEquipment;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSNumber * specialConsideration;
@property (nonatomic, retain) NSNumber * sprayQuality;
@property (nonatomic, retain) NSNumber * startIndex;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSNumber * temperature;
@property (nonatomic, retain) NSNumber * timezoneOffset;
@property (nonatomic, retain) NSNumber * uploaded;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSNumber * windDirection;
@property (nonatomic, retain) NSNumber * windMeter;
@property (nonatomic, retain) NSNumber * windSpeedAvg;
@property (nonatomic, retain) NSNumber * windSpeedMax;
@property (nonatomic, retain) NSNumber * privacy;
@property (nonatomic, retain) NSOrderedSet *points;
@end

@interface MeasurementSession (CoreDataGeneratedAccessors)

- (void)insertObject:(MeasurementPoint *)value inPointsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPointsAtIndex:(NSUInteger)idx;
- (void)insertPoints:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePointsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPointsAtIndex:(NSUInteger)idx withObject:(MeasurementPoint *)value;
- (void)replacePointsAtIndexes:(NSIndexSet *)indexes withPoints:(NSArray *)values;
- (void)addPointsObject:(MeasurementPoint *)value;
- (void)removePointsObject:(MeasurementPoint *)value;
- (void)addPoints:(NSOrderedSet *)values;
- (void)removePoints:(NSOrderedSet *)values;
@end
