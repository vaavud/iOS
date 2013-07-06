//
//  Properties+Util.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 01/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "Property.h"

@interface Property (Util)

+ (NSString*) getAsString:(NSString*) name;

+ (BOOL) getAsBoolean:(NSString*) name;

+ (void) setAsString:(NSString*) value forKey:(NSString*) name;

+ (void) setAsBoolean:(BOOL) value forKey:(NSString*) name;
@end
