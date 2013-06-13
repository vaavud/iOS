//
//  CoreDataManager.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 13/06/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataManager : NSObject

@property (nonatomic, readonly) NSManagedObjectContext* context;

+(CoreDataManager*) sharedInstance;

@end
