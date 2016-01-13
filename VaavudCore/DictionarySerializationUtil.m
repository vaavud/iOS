////
////  DictionarySerialization.m
////  Vaavud
////
////  Created by Thomas Stilling Ambus on 27/06/2013.
////  Copyright (c) 2013 Andreas Okholm. All rights reserved.
////
//
//#import "DictionarySerializationUtil.h"
//
//@implementation DictionarySerializationUtil
//
//+ (NSMutableDictionary *)convertValuesToBasicTypes:(NSDictionary *)dictionary {
//    NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
//    
//    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
//        // remove entries with null values
//        if (object == nil || [object isKindOfClass:[NSNull class]]) {
//            [mutableDictionary removeObjectForKey:key];
//        }
//        // convert NSDate to milliseconds since 1970
//        else if ([object isKindOfClass:[NSDate class]]) {
//            NSNumber *dateMillis = [NSNumber numberWithLongLong:[object timeIntervalSince1970] * 1000.0];
//            [mutableDictionary setObject:dateMillis forKey:key];
//        }
//        // remove invalid numbers
//        else if ([object isKindOfClass:[NSNumber class]] && isnan([object doubleValue])) {
//            [mutableDictionary removeObjectForKey:key];
//        }
//    }];
//    
//    return mutableDictionary;
//}
//
//@end
