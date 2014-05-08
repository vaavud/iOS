//
//  UUIDUtil.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 28/06/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UUIDUtil : NSObject

+ (NSString *) generateUUID;
+ (NSString*) md5Hash:(NSString*)text;

@end
