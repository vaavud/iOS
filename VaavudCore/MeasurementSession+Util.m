////
////  MeasurementSession+Util.m
////  Vaavud
////
////  Created by Thomas Stilling Ambus on 01/07/2013.
////  Copyright (c) 2013 Andreas Okholm. All rights reserved.
////
//
//#import "MeasurementSession+Util.h"
//#import "MeasurementPoint+Util.h"
//#import "DictionarySerializationUtil.h"
//
//@implementation MeasurementSession (Util)
//
//- (NSDictionary *)toDictionary {
//    NSMutableDictionary *dictionary = [[self dictionaryWithValuesForKeys:[[[self entity] attributesByName] allKeys]] mutableCopy];
//
//    dictionary = [DictionarySerializationUtil convertValuesToBasicTypes:dictionary];
//    
//    if (self.timezoneOffset != nil && self.timezoneOffset != (id)[NSNull null]) {
//        // convert stored seconds timezone offset to milliseconds
//        [dictionary setObject:[NSNumber numberWithLong:([self.timezoneOffset longValue] * 1000L)] forKey:@"timezoneOffset"];
//    }
//    
//    // convert inline latitude-longitude to a LatLng object to fit server-side representation
//    if (self.latitude && self.longitude && !(self.latitude == 0 && self.longitude == 0)) {
//        NSDictionary *latLng = [NSDictionary dictionaryWithObjectsAndKeys:self.latitude, @"latitude", self.longitude, @"longitude", nil];
//        [dictionary setObject:latLng forKey:@"position"];
//    }
//    [dictionary removeObjectForKey:@"latitude"];
//    [dictionary removeObjectForKey:@"longitude"];
//    
//    // convert measurement points, if any
//    if (self.points && ([self.points count] > 0) && ([self.endIndex intValue] - [self.startIndex intValue]) > 0) {
//        NSMutableArray *pointsAsDictionaries = [NSMutableArray arrayWithCapacity:([self.endIndex intValue] - [self.startIndex intValue])];
//        int index = 0;
//        for (MeasurementPoint *point in self.points) {
//            
//            if (index >= [self.startIndex intValue] && index < [self.endIndex intValue]) {
//            
//                // convert MeasurementPoint to NSDictionary
//                NSDictionary *pointDictionary = [point toDictionary];
//                [pointsAsDictionaries addObject:pointDictionary];
//            }
//            index++;
//        }
//        
//        [dictionary setObject:pointsAsDictionaries forKey:@"points"];
//    }
//    else {
//        [dictionary removeObjectForKey:@"points"];
//    }
//    
//    return dictionary;
//}
//
//- (NSString *)day {
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"dd MM yyyy"];
//    NSString *result = [dateFormatter stringFromDate:self.startTime];
//    return result;
//}
//
//- (NSString *)sessionCSVFile {
//    NSMutableDictionary *measurementDic = [[self dictionaryWithValuesForKeys:[[[self entity] attributesByName] allKeys]] mutableCopy];
//    
//    // create header
//    NSMutableString *csv = [NSMutableString stringWithString:@""];
//    
//    
//    NSArray *keysOfInterest = [[NSArray alloc] initWithObjects:
//                               @"startTime",
//                               @"endTime",
//                               @"latitude",
//                               @"longitude",
//                               @"geoLocationNameLocalized",
//                               @"windSpeedAvg",
//                               @"windSpeedMax",
//                               @"windDirection",
//                               @"gustiness",
//                               @"humidity",
//                               @"pressure",
//                               @"temperature",
//                               @"windMeter",
//                               @"startTimeUnix",
//                               @"endTimeUnix",
//                               nil];
//
//    NSMutableArray *keysPrintNames = [[NSMutableArray alloc] initWithArray:keysOfInterest];
//    
//    keysPrintNames[[keysPrintNames indexOfObject:@"geoLocationNameLocalized"]] = @"geoLocationName";
//    keysPrintNames[[keysPrintNames indexOfObject:@"windMeter"]] = @"device";
//    
//    // modify some columns
//    measurementDic[@"startTimeUnix"] = @(((NSDate *)measurementDic[@"startTime"]).timeIntervalSince1970);
//    measurementDic[@"endTimeUnix"] = @(((NSDate *)measurementDic[@"endTime"]).timeIntervalSince1970);
//    
//    measurementDic[@"startTime"] = [self dateLocalWithDate:measurementDic[@"startTime"] AndOffset:measurementDic[@"timezoneOffset"]];
//    measurementDic[@"endTime"] = [self dateLocalWithDate:measurementDic[@"endTime"] AndOffset:measurementDic[@"timezoneOffset"]];
//    
//    
//    [csv appendString:[keysPrintNames componentsJoinedByString:@","]];
//    [csv appendString:@"\n"];
//    
//    [keysOfInterest enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
//        [csv appendFormat:@"%@,", [measurementDic[key] isKindOfClass:[NSNull class]] ? @"-" : measurementDic[key]];
//    }];
//    
//    [csv deleteCharactersInRange:NSMakeRange([csv length]-1, 1)];
//    
////    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
////    [formatter setDateFormat:@"'/'yyyy'-'MM'-'dd'_'HH'-'mm'-'ss'-Summary'"];
////    
////    NSString *fileName = [formatter stringFromDate:[NSDate date]];
////    NSLog(@"Filename: %@", fileName);
//    
//    NSError *error;
//    BOOL res = [csv writeToURL:[self filePathURLSummery] atomically:YES encoding:NSUTF8StringEncoding error:&error];
//    if (!res) {
//        NSLog(@"Error %@ while writing to file %@", [error localizedDescription], [self filePathURLSummery] );
//    }
//    
//    NSLog(@"%@", csv);
//    
//    return [self filePathURLSummery].description;
//}
//
//
//- (NSString *)dateLocalWithDate:(NSDate *)date AndOffset:(NSNumber *)offset{
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss' 'Z"];
//    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:offset.integerValue]];
//    return [formatter stringFromDate:date];
//}
//
//-(NSURL *)filePathURLSummery {
//    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
//                                   [self applicationDocumentsDirectory],
//                                   @"summary.csv"]];
//}
//
//-(NSURL *)filePathURLPoints {
//    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
//                                   [self applicationDocumentsDirectory],
//                                   @"points.csv"]];
//}
//
//-(NSString *)applicationDocumentsDirectory
//{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
//    return basePath;
//}
//
//@end
