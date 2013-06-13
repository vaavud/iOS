//
//  SharedSingleton.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 13/06/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#define SHARED_INSTANCE \
+ (id)sharedInstance { \
    static dispatch_once_t once; \
    static id sharedInstance; \
    dispatch_once(&once, ^{ \
        sharedInstance = [[self alloc] init]; \
    }); \
    return sharedInstance; \
}