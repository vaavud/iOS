//
//  CoreDataManager.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 13/06/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "SharedSingleton.h"
#import "CoreDataManager.h"

@implementation CoreDataManager

SHARED_INSTANCE

- (id) init {
    self = [super init];
    if (self) {
        // setup core data DB
        NSString *pathToDB = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/data.db"];
        NSURL *urlToDB = [NSURL fileURLWithPath:pathToDB];

        // migration
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

        // init model, coordinator, and context
        NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
        NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        
        NSError *error;
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:urlToDB options:options error:&error]) {
            NSLog(@"Error: %@", [error localizedFailureReason]);
        }
        else
        {
            _context = [[NSManagedObjectContext alloc] init];
            [_context setPersistentStoreCoordinator:persistentStoreCoordinator];
            [_context setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
        }
    }
    return self;
}

@end
