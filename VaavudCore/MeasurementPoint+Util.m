////
////  MeasurementPoint+Util.m
////  Vaavud
////
////  Created by Thomas Stilling Ambus on 01/07/2013.
////  Copyright (c) 2013 Andreas Okholm. All rights reserved.
////
//
//#import "MeasurementPoint+Util.h"
//#import "DictionarySerializationUtil.h"
//
//@implementation MeasurementPoint (Util)
//
//- (NSDictionary *)toDictionary {
//    
//    NSMutableDictionary *dictionary = [[self dictionaryWithValuesForKeys:[[[self entity] attributesByName] allKeys]] mutableCopy];
//    
//    // remove parent reference to session to avoid cycles
//    [dictionary removeObjectForKey:@"session"];
//    dictionary = [DictionarySerializationUtil convertValuesToBasicTypes:dictionary];
//    
//    return dictionary;
//}
//
//@end
