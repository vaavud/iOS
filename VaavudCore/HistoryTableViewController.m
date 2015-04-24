//
//  HistoryTableViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 24/01/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "Vaavud-Swift.h"
#import "HistoryTableViewController.h"
#import "HistoryTableViewSectionHeaderView.h"
#import "HistoryTableViewCell.h"
#import "MeasurementSession+Util.h"
#import "UIImageView+TMCache.h"
#import "FormatUtil.h"
#import "UnitUtil.h"
#import "Property+Util.h"
#import "Mixpanel.h"
#import "ServerUploadManager.h"
#import "UIColor+VaavudColors.h"
#import "HistoryTableViewCell.h"
#import "RegisterViewController.h"

@import CoreLocation;

@interface HistoryTableViewController ()

@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic) WindSpeedUnit windSpeedUnit;
@property (nonatomic) NSInteger directionUnit;

@property (nonatomic) BOOL isTableUpdating;

@property (nonatomic) NSDateFormatter *dateFormatter;

@property (nonatomic) CLGeocoder *geocoder;

@property (nonatomic) UIActivityIndicatorView *loaderIndicator;

@property (nonatomic) EmptyHistoryArrow *emptyArrow;
@property (nonatomic) UIView *emptyLabelView;
@property (nonatomic) UIView *emptyView;

@property (nonatomic) UIView *backgroundView;

@end

@implementation HistoryTableViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(historySynced) name:@"HistorySynced" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUnits) name:@"UnitChange" object:nil];
        
        self.geocoder = [[CLGeocoder alloc] init];
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.placeholderImage = [UIImage imageNamed:@"map_placeholder.png"];
        
        self.loaderIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self hideVolumeHUD];
    [self setupBackground];
    [self updateUnits];
}

-(void)setupBackground {
    self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.tableView.backgroundView = self.backgroundView;
    
    self.loaderIndicator.center = CGPointMake(CGRectGetMidX(self.backgroundView.bounds), CGRectGetMidY(self.backgroundView.bounds));
    [self.backgroundView addSubview:self.loaderIndicator];

    self.emptyArrow = [[EmptyHistoryArrow alloc] init];
    self.emptyView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.emptyView.alpha = 0;
    
    [self.backgroundView addSubview:self.emptyView];
    [self.emptyView addSubview:self.emptyArrow];
    
    self.emptyLabelView = [[UIView alloc] init];
    
    [self.emptyView addSubview:self.emptyLabelView];
    
    UILabel *upper = [[UILabel alloc] init];
    upper.font = [UIFont fontWithName:@"Helvetica" size:20];
    upper.textColor = [UIColor vaavudColor];
    upper.text = NSLocalizedString(@"HISTORY_NO_MEASUREMENTS", nil);
    [upper sizeToFit];
    [self.emptyLabelView addSubview:upper];
    
    UILabel *lower = [[UILabel alloc] init];
    lower.font = [UIFont fontWithName:@"Helvetica" size:15];
    lower.textColor = [UIColor darkGrayColor];
    lower.text = NSLocalizedString(@"HISTORY_GO_TO_MEASURE", nil);
    [lower sizeToFit];
    [self.emptyLabelView addSubview:lower];
    
    self.emptyLabelView.frame = CGRectMake(0, 0, MAX(CGRectGetWidth(upper.bounds), CGRectGetWidth(lower.bounds)), 60);
    upper.center = CGPointMake(CGRectGetMidX(self.emptyLabelView.bounds), 10);
    lower.center = CGPointMake(CGRectGetMidX(self.emptyLabelView.bounds), 45);
}

-(void)layoutBackground {
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat height = CGRectGetHeight(self.view.bounds);
    CGFloat startY = 0.35*height;
    
    self.emptyArrow.frame = CGRectMake(0, startY, width, height - 60 - startY);
    [self.emptyArrow forceSetup];
    self.emptyLabelView.center = CGPointMake(width/2, startY - 40);
}

-(void)viewDidLayoutSubviews {
//    [self layoutBackground];
//    [self refreshEmptyState];
}

-(void)performSync {
    [[ServerUploadManager sharedInstance] syncHistory:2 ignoreGracePeriod:YES success:^{
        NSLog(@"======= performSync - synced history");
    } failure:^(NSError *error) {
        NSLog(@"======= performSync - FAILED synced history, %@", error);
    }];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.fetchedResultsController = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.emptyArrow reset];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"History Screen"];
        [[Mixpanel sharedInstance] track:@"History Tab"]; // REMOVEME
    }
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (!_fetchedResultsController) {
        _fetchedResultsController = [MeasurementSession MR_fetchAllGroupedBy:@"day" withPredicate:nil sortedBy:@"startTime" ascending:NO delegate:self];
    }
    return _fetchedResultsController;
}

- (void)showLoader {
    [self.loaderIndicator startAnimating];
}

- (void)hideLoader {
    [self.loaderIndicator stopAnimating];
}

- (void)updateUnits {
    self.windSpeedUnit = [Property getAsInteger:KEY_WIND_SPEED_UNIT].intValue;
    self.directionUnit = [Property getAsInteger:KEY_DIRECTION_UNIT defaultValue:0].intValue;
    
    [self.tableView reloadData];
}

- (void)historySynced {
    if ([AccountManager sharedInstance].isLoggedIn) {
        if ([self.fetchedResultsController performFetch:nil]) {
            NSLog(@"- historySynced - Fetched: %ld", (unsigned long)self.fetchedResultsController.fetchedObjects.count);
        }
        [self hideLoader];
        [self refreshEmptyState];
    }
}

- (void)refreshEmptyState {
    if ([AccountManager sharedInstance].isLoggedIn) {
        if ([ServerUploadManager sharedInstance].isHistorySyncBusy) {
            [self showLoader];
            [UIView animateWithDuration:0.2 animations:^{
                self.emptyView.alpha = 0;
            }];
        }
        else {
            [self hideLoader];
            if (self.fetchedResultsController.sections.count == 0) {
                [self.emptyArrow animate];
                [UIView animateWithDuration:0.2 animations:^{
                    self.emptyView.alpha = 1;
                }];
            }
            else {
                [UIView animateWithDuration:0.2 animations:^{
                    self.emptyView.alpha = 0;
                }];
            }
        }
    }
    else {
        self.emptyView.alpha = 0;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.fetchedResultsController.sections.count > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
        return [sectionInfo numberOfObjects];
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    HistoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [self configureCell:cell withSession: [self.fetchedResultsController objectAtIndexPath:indexPath]];
    
    return cell;
}

- (void)configureCell:(HistoryTableViewCell *)cell withSession:(MeasurementSession *)session {
    if (session.latitude && session.longitude && (session.latitude != 0) && (session.longitude != 0)) {
        NSString *iconUrl = @"http://vaavud.com/appgfx/SmallWindMarker.png";
        NSString *markers = [NSString stringWithFormat:@"icon:%@|shadow:false|%f,%f", iconUrl, [session.latitude doubleValue], [session.longitude doubleValue]];
        NSString *staticMapUrl = [NSString stringWithFormat:@"http://maps.google.com/maps/api/staticmap?markers=%@&zoom=15&size=148x148&sensor=true&key=%@", markers, GOOGLE_STATIC_MAPS_API_KEY];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[staticMapUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
        [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
        
        [cell.mapImageView setCachedImageWithURLRequest:request placeholderImage:self.placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            if (image) {
                cell.mapImageView.image = image;
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            if (LOG_HISTORY) NSLog(@"[HistoryTableViewController] Failure loading map thumbnail");
        }];
    }
    else {
        // TODO: exchange with "no map" image
        cell.mapImageView.image = self.placeholderImage;
    }
    
    cell.maxHeadingLabel.text = [NSLocalizedString(@"HEADING_MAX", nil) uppercaseStringWithLocale:[NSLocale currentLocale]]; // LOKALISERA_BORT sedan
    
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
    cell.maxLabel.textColor = [UIColor vaavudColor];
    
    NSString *unitName = [UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit];
    cell.unitLabel.text = unitName;
    
    self.dateFormatter.locale = [NSLocale currentLocale];
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    NSString *time = [[self.dateFormatter stringFromDate:session.startTime] uppercaseStringWithLocale:[NSLocale currentLocale]];
    cell.timeLabel.text = time;
    
    if (session.windMeter && ([session.windMeter integerValue] > 1) && session.windDirection) {
        if (self.directionUnit == 0) {
            cell.directionLabel.text = [UnitUtil displayNameForDirection:session.windDirection];
        }
        else {
            cell.directionLabel.text = [NSString stringWithFormat:@"%.0f°", session.windDirection.floatValue];
        }
        cell.directionImageView.transform = CGAffineTransformMakeRotation(session.windDirection.doubleValue/180 * M_PI);
        
        cell.directionLabel.hidden = NO;
        cell.directionImageView.hidden = NO;
    }
    else {
        cell.directionLabel.hidden = YES;
        cell.directionImageView.hidden = YES;
    }
    
    cell.testModeLabel.hidden = !(cell.testModeLabel && session.testMode.boolValue);
    
    BOOL hasPosition = session.latitude && session.longitude;
    BOOL hasGeoLocality = session.geoLocationNameLocalized != nil;
    
    if (!hasPosition) {
        cell.locationLabel.alpha = 0.3;
        cell.locationLabel.text = NSLocalizedString(@"GEOLOCATION_UNKNOWN", nil);
    }
    else if (!hasGeoLocality) {
        cell.locationLabel.alpha = 0.3;
        cell.locationLabel.text = NSLocalizedString(@"GEOLOCATION_LOADING", nil);
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:session.latitude.doubleValue longitude:session.longitude.doubleValue];
        [self geocodeLocation:location forCell:cell session:session];
    }
    else {
        cell.locationLabel.alpha = 1.0;
        cell.locationLabel.text = session.geoLocationNameLocalized;
    }
}

- (void)geocodeLocation:(CLLocation *)location forCell:(HistoryTableViewCell *)cell session:(MeasurementSession *)session {
    if (LOG_HISTORY) NSLog(@"[HistoryTableViewController] LOCATION requesting for %.2f", session.windSpeedAvg.floatValue);
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.geocoder reverseGeocodeLocation:location completionHandler: ^(NSArray *placemarks, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (LOG_HISTORY) NSLog(@"[HistoryTableViewController] LOCATION received for %.2f", session.windSpeedAvg.floatValue);
                
                if (placemarks.count > 0 && !error) {
                    CLPlacemark *first = [placemarks objectAtIndex:0];
                    NSString *text = first.thoroughfare ?: first.locality ?: first.country;
                    
                    session.geoLocationNameLocalized = text;
                    cell.locationLabel.text = text;
                    session.uploaded = @NO;
                }
                else {
                    if (error) { if (LOG_HISTORY) NSLog(@"[HistoryTableViewController] Geocode failed with error: %@", error); }
                    cell.locationLabel.text = NSLocalizedString(@"GEOLOCATION_ERROR", nil);
                }
                
                cell.locationLabel.alpha = 1.0;
            });
        }];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[ServerUploadManager sharedInstance] triggerUpload];
}

-(void)dealloc {
    NSLog(@"Dealloc HTVC");

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 25;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *HeaderIdentifier = @"HeaderIdentifier";
    
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:HeaderIdentifier];
    
    if (!view) {
        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:HeaderIdentifier];
        view.frame = CGRectMake(0.0, 0.0, tableView.frame.size.width, 25.0);
        view.contentView.backgroundColor = [UIColor vaavudGreyColor];
        
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"HistoryTableViewSectionHeaderView" owner:self options:nil];
        UIView *subview = [topLevelObjects objectAtIndex:0];
        subview.tag = 1;
        subview.frame = view.contentView.bounds;
        [view.contentView addSubview:subview];
    }
    
    id<NSFetchedResultsSectionInfo>sectionInfo = self.fetchedResultsController.sections[section];
    
    self.dateFormatter.dateFormat = @"dd MM yyyy";
    NSDate *date = [self.dateFormatter dateFromString:[sectionInfo name]];
    
    HistoryTableViewSectionHeaderView *headerView = (HistoryTableViewSectionHeaderView *)[view viewWithTag:1];
    
    self.dateFormatter.dateFormat = @"EEEE, MMM d";
    headerView.label.text = [[self.dateFormatter stringFromDate:date] uppercaseStringWithLocale:[NSLocale currentLocale]];
    
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
    }
    
    return view;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MeasurementSession *session = [self.fetchedResultsController objectAtIndexPath:indexPath];
        if (session) {
            [[ServerUploadManager sharedInstance] deleteMeasurementSession:session.uuid retry:3 success:nil failure:nil];
            [session MR_deleteEntity];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
        }
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    NSLog(@"- controllerWillChangeContent");
    
    [self.tableView beginUpdates];
    self.isTableUpdating = YES;
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            // do nothing, never happens
            break;
            
        case NSFetchedResultsChangeMove:
            // do nothing, never happens
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (LOG_HISTORY) NSLog(@"[HistoryTableViewController] Controller changed object");
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate: {
            HistoryTableViewCell *cell = (HistoryTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            MeasurementSession *session = [self.fetchedResultsController objectAtIndexPath:indexPath];
            [self configureCell:cell withSession:session];
            
            break;
        }
    
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (self.isTableUpdating) {
        [self.tableView endUpdates];
        self.isTableUpdating = NO;
    }
    [self refreshEmptyState];
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    return [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow] != nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SummarySegue"]) {
        CoreSummaryViewController *destination = segue.destinationViewController;
        destination.session = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
    }
}

@end
