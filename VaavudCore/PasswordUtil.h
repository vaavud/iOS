//
//  PasswordUtil.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/02/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PasswordUtil : NSObject

+(NSString*) createHash:(NSString*)password salt:(NSString*)salt;

@end
