//
//  HistoryTableViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 24/01/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HistoryRootViewController.h"

@class HistoryTableViewCell;
@class MeasurementSession;

@interface HistoryTableViewController : UITableViewController<HistoryLoadedListener, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

- (void)configureCell:(HistoryTableViewCell *)cell withSession:(MeasurementSession *)session;
- (void)update;

@end
