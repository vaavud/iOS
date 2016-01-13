//
//  FormatUtil.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 03/10/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FormatUtil : NSObject // fixme: refactor away, use formatter

+ (NSString *)formatRelativeDate:(NSDate *)date;
+ (NSString *)formatValueWithTwoDigits:(float)value;
+ (NSString *)formatValueWithThreeDigits:(double)value;

@end
