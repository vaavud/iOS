//
//  ModelManager.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 09/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ModelManager : NSObject // fixme: remove?

//+ (ModelManager *)sharedInstance;
//- (void)initializeModel;
+ (BOOL)isIPhone4;
+ (NSString *)getModel;

@end
