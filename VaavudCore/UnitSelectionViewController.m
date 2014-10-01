//
//  UnitSelectionViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 02/06/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "UnitSelectionViewController.h"
#import "UnitUtil.h"
#import "Property+Util.h"

@interface UnitSelectionViewController ()

@property (nonatomic, strong) NSArray *units;

@end

@implementation UnitSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    }

    self.navigationItem.title = NSLocalizedString(@"HEADING_UNIT", nil);

    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.units = [NSArray arrayWithObjects:
                  [NSNumber numberWithInteger:WindSpeedUnitKMH],
                  [NSNumber numberWithInteger:WindSpeedUnitMS],
                  [NSNumber numberWithInteger:WindSpeedUnitMPH],
                  [NSNumber numberWithInteger:WindSpeedUnitKN],
                  [NSNumber numberWithInteger:WindSpeedUnitBFT], nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.units.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UnitCellIdentifier" forIndexPath:indexPath];
    NSNumber *unit = self.units[indexPath.item];
    cell.textLabel.text = [UnitUtil displayNameForWindSpeedUnit:(int) [unit integerValue]];
    cell.textLabel.textColor = [UIColor darkGrayColor];

    if ([unit integerValue] == [[Property getAsInteger:KEY_WIND_SPEED_UNIT] integerValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSNumber *currentUnit = [Property getAsInteger:KEY_WIND_SPEED_UNIT];
    NSInteger indexOfCurrentUnit = [self.units indexOfObject:currentUnit];
    
    if (indexOfCurrentUnit != indexPath.item) {
        UITableViewCell *currentlySelectedCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:indexOfCurrentUnit inSection:0]];
        if (currentlySelectedCell) {
            currentlySelectedCell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        [Property setAsInteger:self.units[indexPath.item] forKey:KEY_WIND_SPEED_UNIT];
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
