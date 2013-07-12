//
//  QueryStringUtil.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 10/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QueryStringUtil : NSObject

+ (NSDictionary *)parseQueryString:(NSString *)query;

@end
