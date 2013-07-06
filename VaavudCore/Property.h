//
//  Property.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 01/07/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Property : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * value;

@end
