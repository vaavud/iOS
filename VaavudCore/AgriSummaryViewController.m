//
//  AgriSummaryViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 28/10/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "AgriSummaryViewController.h"
#import "UnitUtil.h"
#import "Property+Util.h"
#import "LocationManager.h"
#import "MeasurementAnnotation.h"
#import "Mixpanel.h"

@interface AgriSummaryViewController ()

@property (weak, nonatomic) IBOutlet UILabel *windSpeedHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *windSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *windSpeedUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionHeadingLabel;
@property (weak, nonatomic) IBOutlet UIImageView *directionImageView;
@property (weak, nonatomic) IBOutlet UILabel *directionLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureUnitLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) WindSpeedUnit windSpeedUnit;
@property (nonatomic) NSInteger directionUnit;

@end

@implementation AgriSummaryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.windSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];

    self.windSpeedHeadingLabel.text = [NSLocalizedString(@"HEADING_WIND_SPEED", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.temperatureUnitLabel.text = NSLocalizedString(@"UNIT_CELCIUS", nil);
    self.directionHeadingLabel.text = [NSLocalizedString(@"HEADING_WIND_DIRECTION", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    self.temperatureHeadingLabel.text = [NSLocalizedString(@"HEADING_TEMPERATURE", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];

    self.mapView.delegate = self;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.windSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    self.windSpeedUnitLabel.text = [UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit];
    
    NSNumber *directionUnitNumber = [Property getAsInteger:KEY_DIRECTION_UNIT];
    NSInteger directionUnit = (directionUnitNumber) ? [directionUnitNumber doubleValue] : 0;
    if (self.directionUnit != directionUnit) {
        self.directionUnit = directionUnit;
    }
    
    if (self.measurementSession && self.measurementSession.startTime) {
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        
        self.navigationItem.title = [dateFormatter stringFromDate:self.measurementSession.startTime];
    }
    else {
        self.navigationItem.title = @"";
    }
    
    [self updateMeasuredValues];
    
    if (self.measurementSession && self.measurementSession.latitude && self.measurementSession.longitude) {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([self.measurementSession.latitude doubleValue], [self.measurementSession.longitude doubleValue]);
        if ([LocationManager isCoordinateValid:coordinate]) {
            [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(coordinate, 500, 500) animated:NO];
            
            MeasurementAnnotation *measurementAnnotation = [[MeasurementAnnotation alloc] initWithLocation:coordinate windDirection:self.measurementSession.windDirection];
            [self.mapView addAnnotation:measurementAnnotation];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Agri Summary Screen"];
    }
}

- (void)updateMeasuredValues {
    if (self.measurementSession && self.measurementSession.windSpeedAvg && !isnan([self.measurementSession.windSpeedAvg doubleValue])) {
        self.windSpeedLabel.text = [self formatValue:[UnitUtil displayWindSpeedFromDouble:[self.measurementSession.windSpeedAvg doubleValue] unit:self.windSpeedUnit]];
    }
    else {
        self.windSpeedLabel.text = @"-";
    }
    
    if (self.measurementSession && self.measurementSession.windDirection && !isnan([self.measurementSession.windDirection doubleValue])) {
        
        if (self.directionUnit == 0) {
            self.directionLabel.text = [UnitUtil displayNameForDirection:self.measurementSession.windDirection];
        }
        else {
            self.directionLabel.text = [NSString stringWithFormat:@"%@°", [NSNumber numberWithInt:(int)round([self.measurementSession.windDirection doubleValue])]];
        }
        
        NSString *imageName = [UnitUtil imageNameForDirection:self.measurementSession.windDirection];
        if (imageName) {
            self.directionImageView.image = [UIImage imageNamed:imageName];
            self.directionImageView.hidden = NO;
        }
        else {
            self.directionImageView.hidden = YES;
        }
    }
    else {
        if (self.directionLabel) {
            self.directionLabel.text = @"-";
        }
        if (self.directionImageView) {
            self.directionImageView.hidden = YES;
        }
    }
    
    if (self.measurementSession && self.measurementSession.temperature && [self.measurementSession.temperature floatValue] > 0.0) {
        self.temperatureLabel.text = [self formatValue:[self.measurementSession.temperature floatValue] - KELVIN_TO_CELCIUS];
    }
    else {
        self.temperatureLabel.text = @"-";
    }
}

- (NSString *)formatValue:(double)value {
    if (value > 100.0) {
        return [NSString stringWithFormat: @"%.0f", value];
    }
    else {
        return [NSString stringWithFormat: @"%.1f", value];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    else if ([annotation isKindOfClass:[MeasurementAnnotation class]]) {
        
        static NSString *MeasureAnnotationIdentifier = @"MeasureAnnotationIdentifier";
        
        MeasurementAnnotation *measurementAnnotation = (MeasurementAnnotation *) annotation;
        measurementAnnotation.windSpeedUnit = self.windSpeedUnit;
        
        MKAnnotationView *measureAnnotationView =
        [self.mapView dequeueReusableAnnotationViewWithIdentifier:MeasureAnnotationIdentifier];
        if (measureAnnotationView == nil) {
            
            measureAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:MeasureAnnotationIdentifier];
            measureAnnotationView.canShowCallout = NO;
            measureAnnotationView.opaque = NO;

            /*
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 38, 38)];
            lbl.backgroundColor = [UIColor clearColor];
            lbl.font = [UIFont systemFontOfSize:12];
            lbl.textColor = [UIColor whiteColor];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.tag = 42;
            [measureAnnotationView addSubview:lbl];
            measureAnnotationView.frame = lbl.frame;
             */
        }
        else {
            measureAnnotationView.annotation = annotation;
        }
        
        UIImage *markerImage = nil;
        
        if (measurementAnnotation.windDirection) {
            NSString *imageName = [UnitUtil mapImageNameForDirection:measurementAnnotation.windDirection];
            if (imageName) {
                markerImage = [UIImage imageNamed:imageName];
            }
        }
        if (!markerImage) {
            markerImage = [UIImage imageNamed:@"mapmarker_no_direction.png"];
        }
        
        measureAnnotationView.image = markerImage;
        
        return measureAnnotationView;
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"infoCell" forIndexPath:indexPath];

    if (indexPath.item == 0) {
        cell.textLabel.text = NSLocalizedString(@"AGRI_REDUCING_EQUIPMENT", nil);
        cell.detailTextLabel.text = (self.measurementSession && self.measurementSession.reduceEquipment && [self.measurementSession.reduceEquipment intValue] > 0) ? [self getReducingEquipmentText:[self.measurementSession.reduceEquipment intValue]] : @"-";
    }
    else if (indexPath.item == 1) {
        cell.textLabel.text = NSLocalizedString(@"AGRI_DOSE", nil);
        cell.detailTextLabel.text = (self.measurementSession && self.measurementSession.dose && [self.measurementSession.dose floatValue] > 0.0F) ? [self getDoseText:[self.measurementSession.dose floatValue]] : @"-";
    }
    else if (indexPath.item == 2) {
        cell.textLabel.text = NSLocalizedString(@"AGRI_BOOM_HEIGHT", nil);
        cell.detailTextLabel.text = (self.measurementSession && self.measurementSession.boomHeight && [self.measurementSession.boomHeight intValue] > 0) ? [self getBoomHeightText:[self.measurementSession.boomHeight intValue]] : @"-";
    }
    else if (indexPath.item == 3) {
        cell.textLabel.text = NSLocalizedString(@"AGRI_SPRAY_QUALITY", nil);
        cell.detailTextLabel.text = (self.measurementSession && self.measurementSession.sprayQuality && [self.measurementSession.sprayQuality intValue] > 0) ? [self getSprayQualityText:[self.measurementSession.sprayQuality intValue]] : @"-";
    }
    else if (indexPath.item == 4) {
        cell.textLabel.text = NSLocalizedString(@"AGRI_PROTECTIVE_DISTANCE", nil);
        cell.detailTextLabel.text = (self.measurementSession && self.measurementSession.generalConsideration && self.measurementSession.specialConsideration && [self.measurementSession.generalConsideration intValue] > 0 && [self.measurementSession.specialConsideration intValue] > 0) ? [NSString stringWithFormat:@"%d %@ / %d %@", [self.measurementSession.generalConsideration intValue], NSLocalizedString(@"AGRI_DISTANCE_UNIT_M", nil), [self.measurementSession.specialConsideration intValue], NSLocalizedString(@"AGRI_DISTANCE_UNIT_M", nil)] : @"-";
    }

    cell.textLabel.textColor = [UIColor darkGrayColor];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (NSString *) getReducingEquipmentText:(int)value {
    
    if (value == 1) {
        return NSLocalizedString(@"AGRI_REDUCING_EQUIPMENT_NONE", nil);
    }
    else if (value == 2) {
        return NSLocalizedString(@"AGRI_REDUCING_EQUIPMENT_50", nil);
    }
    else if (value == 3) {
        return NSLocalizedString(@"AGRI_REDUCING_EQUIPMENT_75", nil);
    }
    else if (value == 4) {
        return NSLocalizedString(@"AGRI_REDUCING_EQUIPMENT_90", nil);
    }
    else if (value == 0) {
        return @"";
    }
    else {
        NSLog(@"[AgriSummaryViewController] ERROR: Unknown reducing equipment value %d", value);
        return @"-";
    }
}

- (NSString *)getDoseText:(float)value {
    if (value == 0.25F) {
        return NSLocalizedString(@"AGRI_DOSE_QUARTER", nil);
    }
    else if (value == 0.5F) {
        return NSLocalizedString(@"AGRI_DOSE_HALF", nil);
    }
    else if (value == 1.0F) {
        return NSLocalizedString(@"AGRI_DOSE_FULL", nil);
    }
    else {
        NSLog(@"[AgriSummaryViewController] ERROR: Unknown dose value %f", value);
        return @"-";
    }
}

- (NSString *)getBoomHeightText:(int)value {
    if (value == 25) {
        return NSLocalizedString(@"AGRI_BOOM_HEIGHT_25CM", nil);
    }
    else if (value == 40) {
        return NSLocalizedString(@"AGRI_BOOM_HEIGHT_40CM", nil);
    }
    else if (value == 60) {
        return NSLocalizedString(@"AGRI_BOOM_HEIGHT_60CM", nil);
    }
    else {
        NSLog(@"[AgriSummaryViewController] ERROR: Unknown boom height value %d", value);
        return @"-";
    }
}

- (NSString *)getSprayQualityText:(int)value {
    if (value == 1) {
        return NSLocalizedString(@"AGRI_SPRAY_QUALITY_FINE", nil);
    }
    else if (value == 2) {
        return NSLocalizedString(@"AGRI_SPRAY_QUALITY_MEDIUM", nil);
    }
    else if (value == 3) {
        return NSLocalizedString(@"AGRI_SPRAY_QUALITY_COARSE", nil);
    }
    else if (value == 0) {
        return @"";
    }
    else {
        NSLog(@"[AgriSummaryViewController] ERROR: Unknown spray quality value %d", value);
        return @"-";
    }
}

@end
