//
//  DirectionSelectionTableViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 11/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "DirectionSelectionTableViewController.h"
#import "Property+Util.h"
#import "UnitUtil.h"

@interface DirectionSelectionTableViewController ()

@end

@implementation DirectionSelectionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    }
    
    self.navigationItem.title = NSLocalizedString(@"HEADING_WIND_DIRECTION", nil);
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier" forIndexPath:indexPath];

    cell.textLabel.text = [UnitUtil displayNameForDirectionUnit:indexPath.item];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    
    NSNumber *directionUnit = [Property getAsInteger:KEY_DIRECTION_UNIT];
    NSInteger directionIndex = (directionUnit) ? [directionUnit integerValue] : 0;
    
    if (indexPath.item == directionIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSNumber *directionUnit = [Property getAsInteger:KEY_DIRECTION_UNIT];
    NSInteger directionIndex = (directionUnit) ? [directionUnit integerValue] : 0;
    
    if (directionIndex != indexPath.item) {
        UITableViewCell *currentlySelectedCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:directionIndex inSection:0]];
        if (currentlySelectedCell) {
            currentlySelectedCell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        [Property setAsInteger:[NSNumber numberWithInteger:indexPath.item] forKey:KEY_DIRECTION_UNIT];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

@end
