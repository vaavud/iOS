//
//  MeasurementSession+Util.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 01/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "MeasurementSession+Util.h"
#import "MeasurementPoint+Util.h"
#import "DictionarySerializationUtil.h"

@implementation MeasurementSession (Util)

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dictionary = [[self dictionaryWithValuesForKeys:[[[self entity] attributesByName] allKeys]] mutableCopy];

    dictionary = [DictionarySerializationUtil convertValuesToBasicTypes:dictionary];
    
    if (self.timezoneOffset != nil && self.timezoneOffset != (id)[NSNull null]) {
        // convert stored seconds timezone offset to milliseconds
        [dictionary setObject:[NSNumber numberWithLong:([self.timezoneOffset longValue] * 1000L)] forKey:@"timezoneOffset"];
    }
    
    // convert inline latitude-longitude to a LatLng object to fit server-side representation
    if (self.latitude && self.longitude && !(self.latitude == 0 && self.longitude == 0)) {
        NSDictionary *latLng = [NSDictionary dictionaryWithObjectsAndKeys:self.latitude, @"latitude", self.longitude, @"longitude", nil];
        [dictionary setObject:latLng forKey:@"position"];
    }
    [dictionary removeObjectForKey:@"latitude"];
    [dictionary removeObjectForKey:@"longitude"];
    
    // convert measurement points, if any
    if (self.points && ([self.points count] > 0) && ([self.endIndex intValue] - [self.startIndex intValue]) > 0) {
        NSMutableArray *pointsAsDictionaries = [NSMutableArray arrayWithCapacity:([self.endIndex intValue] - [self.startIndex intValue])];
        int index = 0;
        for (MeasurementPoint *point in self.points) {
            
            if (index >= [self.startIndex intValue] && index < [self.endIndex intValue]) {
            
                // convert MeasurementPoint to NSDictionary
                NSDictionary *pointDictionary = [point toDictionary];
                [pointsAsDictionaries addObject:pointDictionary];
            }
            index++;
        }
        
        [dictionary setObject:pointsAsDictionaries forKey:@"points"];
    }
    else {
        [dictionary removeObjectForKey:@"points"];
    }
    
    return dictionary;
}

- (NSString *)day {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd MM yyyy"];
    NSString *result = [dateFormatter stringFromDate:self.startTime];
    return result;
}

@end
