//
//  ModelManager.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 09/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ModelManager : NSObject

+ (ModelManager *) sharedInstance;

- (void) initializeModel;

@end
