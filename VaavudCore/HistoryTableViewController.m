//
//  HistoryTableViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 24/01/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "HistoryTableViewController.h"
#import "HistoryTableViewSectionHeaderView.h"
#import "HistoryTableViewCell.h"
#import "MeasurementSession+Util.h"
#import "UIImageView+TMCache.h"
#import "FormatUtil.h"
#import "UnitUtil.h"
#import "Property+Util.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "Mixpanel.h"

@interface HistoryTableViewController ()

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic) WindSpeedUnit windSpeedUnit;
@property (nonatomic) NSDate *latestLocalStartTime;

@end

@implementation HistoryTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.placeholderImage = [UIImage imageNamed:@"map_placeholder.png"];
    self.windSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    self.navigationItem.title = NSLocalizedString(@"HISTORY_TITLE", nil);
    
}

- (void)viewDidUnload {
    self.fetchedResultsController = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    BOOL refetch = NO;
    BOOL refresh = NO;

    WindSpeedUnit newWindSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    //NSLog(@"[MapViewController] viewWillAppear: windSpeedUnit=%u", self.windSpeedUnit);
    if (newWindSpeedUnit != self.windSpeedUnit) {
        self.windSpeedUnit = newWindSpeedUnit;
        refresh = YES;
    }

    MeasurementSession *measurementSession = [MeasurementSession MR_findFirstOrderedByAttribute:@"startTime" ascending:NO];
    if (measurementSession && measurementSession != nil && [measurementSession.measuring boolValue] == NO) {
        NSDate *newLatestLocalStartTime = measurementSession.startTime;
        if (newLatestLocalStartTime != nil && (self.latestLocalStartTime == nil || [newLatestLocalStartTime compare:self.latestLocalStartTime] == NSOrderedDescending)) {
            self.latestLocalStartTime = newLatestLocalStartTime;
            refetch = YES;
            refresh = YES;
        }
    }
    
    if (refetch) {
        NSError *error;
        if ([self.fetchedResultsController performFetch:&error]) {
            [self.tableView reloadData];
        }
        else {
            NSLog(@"[HistoryTableViewController] Error refetching data: %@", error);
        }
    }
    else if (refresh) {
        [self.tableView reloadData];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
        [tracker set:kGAIScreenName value:@"History Screen"];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    }
    
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"History Screen"];
    }
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    _fetchedResultsController = [MeasurementSession MR_fetchAllGroupedBy:@"day" withPredicate:nil sortedBy:@"startTime" ascending:NO delegate:nil];
    return _fetchedResultsController;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        //NSLog(@"numberOfRowsInSection=%lu", (unsigned long)[sectionInfo numberOfObjects]);
        return [sectionInfo numberOfObjects];
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    HistoryTableViewCell *cell = (HistoryTableViewCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    MeasurementSession *session = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (session.latitude && session.longitude && (session.latitude != 0) && (session.longitude != 0)) {
        NSString *iconUrl = @"http://vaavud.com/appgfx/SmallWindMarker.png";
        NSString *markers = [NSString stringWithFormat:@"icon:%@|shadow:false|%f,%f", iconUrl, [session.latitude doubleValue], [session.longitude doubleValue]];
        NSString *staticMapUrl = [NSString stringWithFormat:@"http://maps.google.com/maps/api/staticmap?markers=%@&zoom=15&size=148x148&sensor=true&key=%@", markers, GOOGLE_STATIC_MAPS_API_KEY];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[staticMapUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
        [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
        
        /*
        NSURLCache *cache = [NSURLCache sharedURLCache];
        NSCachedURLResponse *cachedResponse = [cache cachedResponseForRequest:request];
        BOOL cachedHit = (cachedResponse != nil);
        NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
        [dayFormatter setDateFormat:@"dd-MM HH:mm"];
        NSString *dtime = [dayFormatter stringFromDate:session.startTime];
        NSLog(@"%@ h=%d (%f,%f)", dtime, cachedHit, [session.latitude doubleValue], [session.longitude doubleValue]);
        */
        
        [cell.mapImageView setCachedImageWithURLRequest:request placeholderImage:self.placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            if (image) {
                //NSLog(@"%@, Cache-Control:%@", dtime, [response.allHeaderFields valueForKey:@"Cache-Control"]);
                cell.mapImageView.image = image;
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            NSLog(@"Failure loading map thumbnail");
        }];
    }
    else {
        // TODO: exchange with "no map" image
        cell.mapImageView.image = self.placeholderImage;
    }
    
    cell.maxHeadingLabel.text = [NSLocalizedString(@"HEADING_MAX", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    
    if (session.windSpeedAvg != nil && !isnan([session.windSpeedAvg doubleValue])) {
        cell.avgLabel.text = [FormatUtil formatValueWithThreeDigits:[UnitUtil displayWindSpeedFromDouble:[session.windSpeedAvg doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        cell.avgLabel.text = @"- ";
    }
    
    if (session.windSpeedMax != nil && !isnan([session.windSpeedMax doubleValue])) {
        cell.maxLabel.text = [FormatUtil formatValueWithThreeDigits:[UnitUtil displayWindSpeedFromDouble:[session.windSpeedMax doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        cell.maxLabel.text = @" -";
    }
    
    NSString *unitName = [UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit];
    cell.unitLabel.text = unitName;

    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
    [dayFormatter setLocale:[NSLocale currentLocale]];
    [dayFormatter setDateStyle:NSDateFormatterNoStyle];
    [dayFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *time = [[[dayFormatter stringFromDate:session.startTime] stringByReplacingOccurrencesOfString:@"." withString:@":"] uppercaseStringWithLocale:[NSLocale currentLocale]];
    cell.timeLabel.text = time;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 36;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *HeaderIdentifier = @"HeaderIdentifier";
    
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:HeaderIdentifier];
    
    if (!view) {
        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:HeaderIdentifier];
        view.frame = CGRectMake(0.0F, 0.0F, tableView.frame.size.width, 36.0F);
        view.contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];

        NSArray* topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"HistoryTableViewSectionHeaderView" owner:self options:nil];
        UIView *subview = [topLevelObjects objectAtIndex:0];
        subview.tag = 1;
        subview.frame = CGRectMake(0.0F, -1.0F, tableView.frame.size.width, 38.0F);
        [view.contentView addSubview:subview];

        //NSLog(@"frame=(%f,%f,%f,%f)", subview.frame.origin.x, subview.frame.origin.y, subview.frame.size.width, subview.frame.size.height);

    }
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd MM yyyy"];
    NSDate *date = [dateFormatter dateFromString:[sectionInfo name]];

    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
    [dayFormatter setDateFormat:@"d"];
    NSString *day = [dayFormatter stringFromDate:date];

    NSDateFormatter *monthFormatter = [[NSDateFormatter alloc] init];
    [monthFormatter setDateFormat:@"MMM"];
    NSString *month = [[[monthFormatter stringFromDate:date] stringByReplacingOccurrencesOfString:@"." withString:@""] uppercaseStringWithLocale:[NSLocale currentLocale]];

    HistoryTableViewSectionHeaderView *headerView = (HistoryTableViewSectionHeaderView*) [view viewWithTag:1];
    headerView.monthLabel.text = month;
    headerView.dayLabel.text = day;
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // note: apparently 0 means default, so return number very close to zero to trick the height to zero
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    static NSString *FooterIdentifier = @"FooterIdentifier";
    
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:FooterIdentifier];
    
    if (!view) {
        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:FooterIdentifier];
        view.frame = CGRectZero;
        //view.contentView.backgroundColor = [UIColor redColor];
    }
    
    return view;
}

@end
