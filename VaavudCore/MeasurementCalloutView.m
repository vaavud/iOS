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
#import "UIImageView+TMCache.h"
#import "FormatUtil.h"
#import "MeasurementTableViewCell.h"
#import "UIColor+VaavudColors.h"

static NSString *cellIdentifier = @"MeasurementCell";

@implementation MeasurementCalloutView

BOOL isTableInitialized = NO;

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        isTableInitialized = NO;
    }
    return self;
}

-(void)layoutSubviews {
    if (!isTableInitialized) {
        UINib *cellNib = [UINib nibWithNibName:@"MeasurementTableViewCell" bundle:nil];
        [self.tableView registerNib:cellNib forCellReuseIdentifier:cellIdentifier];
        isTableInitialized = YES;
    }
    [super layoutSubviews];
}

-(void)setMeasurementAnnotation:(MeasurementAnnotation*)measurementAnnotation {
    _measurementAnnotation = measurementAnnotation;
    
    self.maxHeadingLabel.text = [NSLocalizedString(@"HEADING_MAX", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
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
    self.maxLabel.textColor = [UIColor vaavudColor];
    
    NSString *unitName = [UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit];
    self.avgUnitLabel.text = unitName;
    
    NSString *iconUrl = @"http://vaavud.com/appgfx/SmallWindMarker.png";
    NSString *markers = [NSString stringWithFormat:@"icon:%@|shadow:false|%f,%f", iconUrl, self.measurementAnnotation.coordinate.latitude, self.measurementAnnotation.coordinate.longitude];
    NSString *staticMapUrl = [NSString stringWithFormat:@"http://maps.google.com/maps/api/staticmap?markers=%@&zoom=15&size=224x224&sensor=true&key=%@", markers, GOOGLE_STATIC_MAPS_API_KEY];
    
    [self.imageView setCachedImageWithURL:[NSURL URLWithString:[staticMapUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:self.placeholderImage];
    
    self.timeLabel.text = [FormatUtil formatRelativeDate:measurementAnnotation.startTime];

    if (self.measurementAnnotation.windDirection) {
        
        if (self.directionUnit == 0) {
            self.directionLabel.text = [UnitUtil displayNameForDirection:self.measurementAnnotation.windDirection];
        }
        else {
            self.directionLabel.text = [NSString stringWithFormat:@"%@°", [NSNumber numberWithInt:(int)round([self.measurementAnnotation.windDirection doubleValue])]];
        }
        self.directionLabel.hidden = NO;
        
        NSString *imageName = [UnitUtil imageNameForDirection:self.measurementAnnotation.windDirection];
        if (imageName) {
            self.directionImageView.image = [UIImage imageNamed:imageName];
            self.directionImageView.hidden = NO;
        }
        else {
            self.directionImageView.hidden = YES;
        }
    }
    else {
        self.directionImageView.hidden = YES;
        self.directionLabel.hidden = YES;
    }
    
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
    [self.mapViewController googleAnalyticsAnnotationEvent:self.measurementAnnotation withAction:@"map thumbnail touch" mixpanelTrack:@"Map Marker Thumbnail Zoom" mixpanelSource:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ROW_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.nearbyAnnotations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MeasurementTableViewCell *cell = (MeasurementTableViewCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    MeasurementAnnotation *measurementAnnotation = [self.nearbyAnnotations objectAtIndex:[indexPath item]];
    [cell setValues:measurementAnnotation.avgWindSpeed unit:self.windSpeedUnit time:measurementAnnotation.startTime windDirection:measurementAnnotation.windDirection directionUnit:self.directionUnit];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.mapViewController.isSelectingFromTableView = YES;
    MeasurementAnnotation *measurementAnnotation = [self.nearbyAnnotations objectAtIndex:[indexPath item]];
    [self.mapViewController.mapView selectAnnotation:measurementAnnotation animated:NO];
}

@end
