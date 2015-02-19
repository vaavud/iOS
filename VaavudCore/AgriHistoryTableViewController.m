//
//  AgriHistoryTableViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 28/10/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AgriHistoryTableViewController.h"
#import "AgriSummaryViewController.h"
#import "HistoryTableViewCell.h"

@interface AgriHistoryTableViewController ()

@property (nonatomic, strong) MeasurementSession *segueMeasurementSession;

@end

@implementation AgriHistoryTableViewController

- (void)configureCell:(HistoryTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    [super configureCell:cell atIndexPath:indexPath];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.segueMeasurementSession = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"summarySegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *controller = [segue destinationViewController];
    if ([controller isKindOfClass:[AgriSummaryViewController class]]) {
        AgriSummaryViewController *consumer = (AgriSummaryViewController *)controller;
        consumer.measurementSession = self.segueMeasurementSession;
    }
    self.segueMeasurementSession = nil;
}

@end
