//
//  MeasurementCalloutView.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 30/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "MeasurementCalloutView.h"
#import "UnitUtil.h"
#import "Property+Util.h"
#import "UIImageView+AFNetworking.h"
#import "FormatUtil.h"
#import "MeasurementTableViewCell.h"

@implementation MeasurementCalloutView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

-(void)setMeasurementAnnotation:(MeasurementAnnotation*)measurementAnnotation {
    _measurementAnnotation = measurementAnnotation;
    
    self.maxHeadingLabel.text = NSLocalizedString(@"HEADING_MAX", nil);
    self.nearbyHeadingLabel.text = [NSLocalizedString(@"HEADING_NEARBY_MEASUREMENTS", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
    
    if (!isnan(self.measurementAnnotation.avgWindSpeed)) {
        self.avgLabel.text = [FormatUtil formatValueWithThreeDigits:[UnitUtil displayWindSpeedFromDouble:self.measurementAnnotation.avgWindSpeed unit:self.windSpeedUnit]];
    }
    else {
        self.avgLabel.text = @"-";
    }
    
    if (!isnan(self.measurementAnnotation.maxWindSpeed)) {
        self.maxLabel.text = [FormatUtil formatValueWithThreeDigits:[UnitUtil displayWindSpeedFromDouble:self.measurementAnnotation.maxWindSpeed unit:self.windSpeedUnit]];
    }
    else {
        self.maxLabel.text = @"-";
    }
    
    NSString *unitName = [UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit];
    self.avgUnitLabel.text = unitName;
    self.maxUnitLabel.text = unitName;
    
    NSString *iconUrl = @"http://vaavud.com/appgfx/SmallWindMarker.png";
    NSString *markers = [NSString stringWithFormat:@"icon:%@|shadow:false|%f,%f", iconUrl, self.measurementAnnotation.coordinate.latitude, self.measurementAnnotation.coordinate.longitude];

    NSString *staticMapUrl = [NSString stringWithFormat:@"http://maps.google.com/maps/api/staticmap?markers=%@&zoom=15&size=224x224&sensor=true", markers];
    
    [self.imageView setImageWithURL:[NSURL URLWithString:[staticMapUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    
    self.timeLabel.text = [FormatUtil formatRelativeDate:measurementAnnotation.startTime];

    if (self.nearbyAnnotations.count == 0) {
        [self.tableView removeFromSuperview];
        [[self viewWithTag:1] removeFromSuperview]; // remove "Nearby Measurements" view
    }
    else {
        UITableView *measureTableView = self.tableView;
        measureTableView.delegate = self;
        measureTableView.dataSource = self;
    }
}

- (IBAction) mapButtonTapped {
    [self.mapViewController zoomToAnnotation:self.measurementAnnotation];
    [self.mapViewController googleAnalyticsAnnotationEvent:self.measurementAnnotation withAction:@"map thumbnail touch"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ROW_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.nearbyAnnotations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"MeasurementCell";
    
    MeasurementTableViewCell *cell = (MeasurementTableViewCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        NSArray* topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"MeasurementTableViewCell" owner:self options:nil];
        cell = (MeasurementTableViewCell*) [topLevelObjects objectAtIndex:0];
    }
    
    cell.backgroundColor = [UIColor clearColor];
    
    MeasurementAnnotation *measurementAnnotation = [self.nearbyAnnotations objectAtIndex:[indexPath item]];
    [cell setValues:measurementAnnotation.avgWindSpeed unit:self.windSpeedUnit time:measurementAnnotation.startTime];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.mapViewController.isSelectingFromTableView = YES;
    MeasurementAnnotation *measurementAnnotation = [self.nearbyAnnotations objectAtIndex:[indexPath item]];
    [self.mapViewController.mapView selectAnnotation:measurementAnnotation animated:NO];
}

@end
