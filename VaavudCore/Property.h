//
//  Property.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 26/08/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Property : NSManagedObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *value;

@end
