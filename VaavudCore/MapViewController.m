//
//  MapViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 23/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "MapViewController.h"
#import "MeasurementAnnotation.h"
#import "UnitUtil.h"
#import "Property+Util.h"
#import "CustomSMCalloutDrawnBackgroundView.h"
#import "MeasurementCalloutView.h"
#import "FormatUtil.h"
#import "LocationManager.h"
#import "ServerUploadManager.h"

#define MERCATOR_RADIUS 85445659.44705395
#define MAX_GOOGLE_LEVELS 20
#define CALLOUT_ADDITIONAL_HEIGHT 42.0
#define graceTimeBetweenMeasurementsRead 300.0

@interface MapViewController ()
@property (nonatomic) WindSpeedUnit windSpeedUnit;
@property (nonatomic) MeasurementCalloutView *measurementCalloutView;
@property(nonatomic) NSDate *lastMeasurementsRead;
@property (nonatomic) int hoursAgo;
@end

@implementation MapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.isSelectingFromTableView = NO;
    self.hoursAgo = 48;

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        UIImage *selectedTabImage = [[UIImage imageNamed:@"map_selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.tabBarItem.selectedImage = selectedTabImage;
    }

	self.mapView.delegate = self;
    
    self.mapView.calloutView = [SMCalloutView new];
    self.mapView.calloutView.delegate = self;
    self.windSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    
    [self refreshHours];
    [self.unitButton setTitle:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit] forState:UIControlStateNormal];
    
    CLLocationCoordinate2D latestLocation = [LocationManager sharedInstance].latestLocation;
    if ([LocationManager isCoordinateValid:latestLocation]) {
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(latestLocation, 200000, 200000) animated:YES];
    }
    else {
        // TODO: set default location if user's location is unknown
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    WindSpeedUnit newWindSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    //NSLog(@"[MapViewController] viewWillAppear: windSpeedUnit=%u", self.windSpeedUnit);
    if (newWindSpeedUnit != self.windSpeedUnit) {
        self.windSpeedUnit = newWindSpeedUnit;
        [self windSpeedUnitChanged];
        [self.unitButton setTitle:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit] forState:UIControlStateNormal];
    }
    [self loadMeasurements:NO];
}

- (void) viewDidAppear:(BOOL)animated {
    // note: hack for content view underlapping tab view when clicking on another tab and back
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") && (self.hoursBottomLayoutGuideConstraint != nil)) {
        [self.view removeConstraint:self.hoursBottomLayoutGuideConstraint];
        self.hoursBottomLayoutGuideConstraint = nil;
        NSLayoutConstraint *bottomSpaceConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:self.hoursButton
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                multiplier:1.0
                                                                                  constant:49.0+5.0];
        [self.view addConstraint:bottomSpaceConstraint];
    }
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") && (self.unitBottomLayoutGuideConstraint != nil)) {
        [self.view removeConstraint:self.unitBottomLayoutGuideConstraint];
        self.unitBottomLayoutGuideConstraint = nil;
        NSLayoutConstraint *bottomSpaceConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:self.unitButton
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                multiplier:1.0
                                                                                  constant:49.0+5.0];
        [self.view addConstraint:bottomSpaceConstraint];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadMeasurements:(BOOL)ignoreGracePeriod {
    
    if (!ignoreGracePeriod && self.lastMeasurementsRead && self.lastMeasurementsRead != nil) {
        NSTimeInterval howRecent = [self.lastMeasurementsRead timeIntervalSinceNow];
        if (abs(howRecent) < graceTimeBetweenMeasurementsRead) {
            //NSLog(@"[MapViewController] ignoring loadMeasurements due to grace period");
            return;
        }
    }
    
    [[ServerUploadManager sharedInstance] readMeasurements:self.hoursAgo retry:3 success:^(NSArray *measurements) {
        NSLog(@"[MapViewController] read measurements");

        self.lastMeasurementsRead = [NSDate date];

        [self refreshHours];

        if (self.mapView.selectedAnnotations.count > 0) {
            [self.mapView deselectAnnotation:self.mapView.selectedAnnotations[0] animated:NO];
        }

        if ([self.mapView.annotations count] > 0) {
            [self.mapView removeAnnotations:self.mapView.annotations];
        }
        
        for (NSArray *measurement in measurements) {
            
            if (measurement.count >= 5) {
                double latitude = [((NSString*)[measurement objectAtIndex:0]) doubleValue];
                double longitude = [((NSString*)[measurement objectAtIndex:1]) doubleValue];
                NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:([((NSString*)[measurement objectAtIndex:2]) doubleValue] / 1000.0)];
                float windSpeedAvg = ([measurement objectAtIndex:3] == nil) ? 0.0 : [((NSString*)[measurement objectAtIndex:3]) floatValue];
                float windSpeedMax = ([measurement objectAtIndex:4] == nil) ? 0.0 : [((NSString*)[measurement objectAtIndex:4]) floatValue];
                
                MeasurementAnnotation *measurementAnnotation = [[MeasurementAnnotation alloc] initWithLocation:CLLocationCoordinate2DMake(latitude,longitude) startTime:startTime avgWindSpeed:windSpeedAvg maxWindSpeed:windSpeedMax];
                [self.mapView addAnnotation:measurementAnnotation];
            }
        }
    }];
}

-(void)windSpeedUnitChanged {
    NSArray *annotations = self.mapView.annotations;
    if ([annotations count] > 0) {
        if (self.mapView.selectedAnnotations.count > 0) {
            [self.mapView deselectAnnotation:self.mapView.selectedAnnotations[0] animated:NO];
        }
        
        [self.mapView removeAnnotations:annotations];
        [self.mapView addAnnotations:annotations];
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    else if ([annotation isKindOfClass:[MeasurementAnnotation class]]) {

        static NSString *MeasureAnnotationIdentifier = @"MeasureAnnotationIdentifier";
        
        MeasurementAnnotation *measurementAnnotation = (MeasurementAnnotation*) annotation;
        measurementAnnotation.windSpeedUnit = self.windSpeedUnit;
        
        MKAnnotationView *measureAnnotationView =
        [self.mapView dequeueReusableAnnotationViewWithIdentifier:MeasureAnnotationIdentifier];
        if (measureAnnotationView == nil) {
            
            measureAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:MeasureAnnotationIdentifier];
            measureAnnotationView.canShowCallout = NO;
            
            UIImage *markerImage = [UIImage imageNamed:@"WindMarker.png"];
            measureAnnotationView.image = markerImage;
            measureAnnotationView.opaque = NO;
            
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
            lbl.backgroundColor = [UIColor clearColor];
            lbl.font = [UIFont systemFontOfSize:12];
            lbl.textColor = [UIColor whiteColor];
            lbl.textAlignment = NSTextAlignmentCenter;
            //lbl.alpha = 0.5;
            lbl.tag = 42;
            [measureAnnotationView addSubview:lbl];
            measureAnnotationView.frame = lbl.frame;
            
        }
        else
        {
            measureAnnotationView.annotation = annotation;
        }
        
        UILabel *lbl = (UILabel *)[measureAnnotationView viewWithTag:42];
        lbl.text = [FormatUtil formatValueWithTwoDigits:[UnitUtil displayWindSpeedFromDouble:measurementAnnotation.avgWindSpeed unit:self.windSpeedUnit]];
        
        return measureAnnotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
	if ([view.annotation isKindOfClass:[MeasurementAnnotation class]]) {

        NSArray *nearbyAnnotations;
        
        //NSLog(@"zoomLevel=%f", [self.mapView getZoomLevel]);
        
        if ([self.mapView getZoomLevel] <= 2) {
            nearbyAnnotations = [NSArray arrayWithObjects: nil];
        }
        else {
            nearbyAnnotations = [self findNearbyAnnotations:view.annotation];
        }
        
        float height = 300.0;
        if (nearbyAnnotations.count == 0) {
            height = 112.0;
        }
        else if (nearbyAnnotations.count < 4) {
            height -= (28.0 /* extra half cell to show you can scroll */ + (3 - nearbyAnnotations.count) * (ROW_HEIGHT));
        }
        
        //NSLog(@"desired height=%f", height);
        
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, height)];

        NSArray* topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"MeasurementCalloutView" owner:self options:nil];
        self.measurementCalloutView = (MeasurementCalloutView*) [topLevelObjects objectAtIndex:0];
        self.measurementCalloutView.frame = CGRectMake(0, 0, 280, height);
        self.measurementCalloutView.mapViewController = self;
        self.measurementCalloutView.windSpeedUnit = self.windSpeedUnit;
        self.measurementCalloutView.nearbyAnnotations = nearbyAnnotations;
        self.measurementCalloutView.measurementAnnotation = view.annotation;
        [containerView addSubview:self.measurementCalloutView];
                        
        self.mapView.calloutView.contentView = containerView;
        self.mapView.calloutView.backgroundView = [CustomSMCalloutDrawnBackgroundView new];
        
        [self.mapView.calloutView presentCalloutFromRect:view.bounds
                                         inView:view
                              constrainedToView:mapView
                       permittedArrowDirections:SMCalloutArrowDirectionDown
                                       animated:!self.isSelectingFromTableView];
        self.isSelectingFromTableView = NO;
	}
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
	if ([view.annotation isKindOfClass:[MeasurementAnnotation class]]) {
		if (self.mapView.calloutView.window) {
            [self.mapView.calloutView dismissCalloutAnimated:NO];
            self.measurementCalloutView = nil;
        }
	}
}

- (NSTimeInterval)calloutView:(SMCalloutView *)theCalloutView delayForRepositionWithSize:(CGSize)offset {

    if (self.mapView.selectedAnnotations.count > 0) {
        id<MKAnnotation> annotation = (id<MKAnnotation>) self.mapView.selectedAnnotations[0];

        // TODO: this is an approximation that will not necessarily hold at target latitude
        CGFloat pixelsPerDegreeLat = self.mapView.frame.size.height / self.mapView.region.span.latitudeDelta;
        CGFloat pixelsPerDegreeLon = self.mapView.frame.size.width / self.mapView.region.span.longitudeDelta;
        
        CGFloat topLayoutGuide = (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") ? self.topLayoutGuide.length : 15.0);
        CLLocationDegrees longitudinalShift = -(offset.width / pixelsPerDegreeLon);
        
        float calloutHeight = (self.measurementCalloutView ? self.measurementCalloutView.frame.size.height : 0.0) + CALLOUT_ADDITIONAL_HEIGHT;
        //NSLog(@"calloutHeight=%f", calloutHeight);
        float ypixelShift = (self.mapView.frame.size.height / 2.0) - topLayoutGuide - calloutHeight;
        CLLocationDegrees latitudinalShift = ypixelShift / pixelsPerDegreeLat;
        CGFloat lat = annotation.coordinate.latitude - latitudinalShift;
        
        CGFloat lon = self.mapView.region.center.longitude + longitudinalShift;
        CLLocationCoordinate2D newCenterCoordinate = (CLLocationCoordinate2D){lat, lon};
        if (fabsf(newCenterCoordinate.latitude) <= 90 && fabsf(newCenterCoordinate.longitude <= 180)) {
            //NSLog(@"[MapViewController] delayForRepositionWithSize - setCenterCoordinate");
            [self.mapView setCenterCoordinate:newCenterCoordinate animated:YES];
        }
    }
    
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

-(void)zoomToAnnotation:(MeasurementAnnotation*)annotation {
    [self.mapView deselectAnnotation:annotation animated:NO];
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(annotation.coordinate, 500, 500) animated:YES];
}

- (NSArray*) findNearbyAnnotations:(MeasurementAnnotation*)annotation {

    MKMapRect mRect = self.mapView.visibleMapRect;
    MKMapPoint eastMapPoint = MKMapPointMake(MKMapRectGetMinX(mRect), MKMapRectGetMidY(mRect));
    MKMapPoint westMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), MKMapRectGetMidY(mRect));
    double mapWidthMeters = MKMetersBetweenMapPoints(eastMapPoint, westMapPoint);

    //NSLog(@"zoom=%f, width=%f km", [self.mapView getZoomLevel], mapWidthMeters / 1000);
    
    double nearbyFraction = 1.0/3.0;
    
    MKMapPoint center = MKMapPointForCoordinate(annotation.coordinate);
    double pointsPerMeter = MKMapPointsPerMeterAtLatitude(annotation.coordinate.latitude);
    double nearbyPoints = pointsPerMeter * mapWidthMeters * nearbyFraction;
    MKMapRect mapRect = MKMapRectMake(center.x - (nearbyPoints/2.0), center.y - (nearbyPoints/2.0), nearbyPoints, nearbyPoints );
    
    
    //NSLog(@"center.x=%f, center.y=%f, pointsPerMeter=%f, nearbyPoints=%f, mapRect.origin.x=%f, mapRect.origin.y=%f, mapRect.size.width=%f, mapRect.size.height=%f", center.x, center.y, pointsPerMeter, nearbyPoints, mapRect.origin.x, mapRect.origin.y, mapRect.size.width, mapRect.size.height);
    
    NSSet *set = [self.mapView annotationsInMapRect:mapRect];
    
    if (set.count == 0) {
        return [NSArray arrayWithObject:nil];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:NO];
    NSArray *sortedArray = [set sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:sortedArray.count];
    [mutableArray addObjectsFromArray:sortedArray];
    [mutableArray removeObject:annotation];
    
    //NSLog(@"[MeasurementCalloutView] nearbyAnnotations=%@", mutableArray);
    
    return mutableArray;
}

- (IBAction) hoursButtonPushed {
    switch (self.hoursAgo) {
        case 24:
            self.hoursAgo = 48;
            break;
        case 48:
            self.hoursAgo = 72;
            break;
        case 72:
            self.hoursAgo = 24;
            break;
        default:
            self.hoursAgo = 48;
    }
    
    [self refreshHours];
    [self loadMeasurements:YES];
}

- (void) refreshHours {
    NSString *hoursAgo = [NSString stringWithFormat:@"%d hours", self.hoursAgo];
    [self.hoursButton setTitle:hoursAgo forState:UIControlStateNormal];
}

- (IBAction) unitButtonPushed {
    self.windSpeedUnit = [UnitUtil nextWindSpeedUnit:self.windSpeedUnit];
    [Property setAsInteger:[NSNumber numberWithInt:self.windSpeedUnit] forKey:KEY_WIND_SPEED_UNIT];
    
    [self.unitButton setTitle:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit] forState:UIControlStateNormal];
    [self windSpeedUnitChanged];
}

@end

@interface MKMapView (UIGestureRecognizer)

// this tells the compiler that MKMapView actually implements this method
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;

@end

@implementation CustomMapView

// override UIGestureRecognizer's delegate method so we can prevent MKMapView's recognizer from firing
// when we interact with UIControl subclasses inside our callout view.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if (self.isTouchWithinCallout) {
        return NO;
    }
    else {
        return [super gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
    }
}

// Allow touches to be sent to our calloutview.
// See this for some discussion of why we need to override this: https://github.com/nfarina/calloutview/pull/9
- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    UIView *calloutMaybe = [self.calloutView hitTest:[self.calloutView convertPoint:point fromView:self] withEvent:event];
    if (calloutMaybe) {
        self.isTouchWithinCallout = YES;
        return calloutMaybe;
    }
    self.isTouchWithinCallout = NO;
    
    return [super hitTest:point withEvent:event];
}

- (double)getZoomLevel {
    CLLocationDegrees longitudeDelta = self.region.span.longitudeDelta;
    CGFloat mapWidthInPixels = self.bounds.size.width;
    double zoomScale = longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * mapWidthInPixels);
    double zoomer = MAX_GOOGLE_LEVELS - log2(zoomScale);
    if (zoomer < 0) zoomer = 0;
    //zoomer = round(zoomer);
    return zoomer;
}

@end
