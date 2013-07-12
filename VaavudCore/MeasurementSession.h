//
//  MeasurementSession.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MeasurementPoint;

@interface MeasurementSession : NSManagedObject

@property (nonatomic, retain) NSString * device;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * measuring;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSNumber * uploaded;
@property (nonatomic, retain) NSNumber * uploadedIndex;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSNumber * windDirection;
@property (nonatomic, retain) NSNumber * windSpeedAvg;
@property (nonatomic, retain) NSNumber * windSpeedMax;
@property (nonatomic, retain) NSNumber * timezoneOffset;
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
