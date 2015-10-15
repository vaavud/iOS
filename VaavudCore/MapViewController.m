//
//  MapViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 23/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "Vaavud-Swift.h"
#import "MapViewController.h"
#import "MeasurementAnnotation.h"
#import "UnitUtil.h"
#import "Property+Util.h"
#import "CustomSMCalloutDrawnBackgroundView.h"
#import "MeasurementCalloutView.h"
#import "FormatUtil.h"
#import "LocationManager.h"
#import "ServerUploadManager.h"
#import "Mixpanel.h"
#import "TabBarController.h"
#import "MixpanelUtil.h"
#import <MediaPlayer/MediaPlayer.h>

#include <math.h>

#define MERCATOR_RADIUS 85445659.44705395
#define MAX_GOOGLE_LEVELS 20
#define CALLOUT_ADDITIONAL_HEIGHT 42.0
#define graceTimeBetweenMeasurementsRead 300.0
#define MAX_NEARBY_MEASUREMENTS 50

@interface MapViewController ()

@property (nonatomic) WindSpeedUnit windSpeedUnit;
@property (nonatomic) NSInteger directionUnit;
@property (nonatomic) MeasurementCalloutView *measurementCalloutView;
@property (nonatomic) NSDate *lastMeasurementsRead;
@property (nonatomic) BOOL isLoading;
@property (nonatomic) int hoursAgo;
@property (nonatomic) double analyticsGridDegree;
@property (nonatomic) NSDate *latestLocalStartTime;
@property (nonatomic) NSInteger latestLocalNumberOfMeasurements;
@property (nonatomic) NSTimer *refreshTimer;
@property (nonatomic) UIImage *placeholderImage;
@property (nonatomic) NSDate *viewAppearedTime;
@property (nonatomic) NSTimer *showGuideViewTimer;

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self hideVolumeHUD];
    
    //NSLog(@"[MapViewController] viewDidLoad");

    self.isLoading = NO;
    self.isSelectingFromTableView = NO;
    self.analyticsGridDegree = [[Property getAsDouble:KEY_ANALYTICS_GRID_DEGREE] doubleValue];
    self.latestLocalNumberOfMeasurements = 0;

    NSNumber *number = [Property getAsInteger:KEY_MAP_HOURS];
    self.hoursAgo = (number ? [number intValue] : 24);
    NSArray *hourOptions = [Property getAsFloatArray:KEY_HOUR_OPTIONS];
    if (hourOptions != nil && hourOptions.count > 0) {
        BOOL optionFound = NO;
        for (NSNumber *hourOption in hourOptions) {
            int option = round([hourOption floatValue]);
            if (self.hoursAgo == option) {
                optionFound = YES;
                break;
            }
        }
        if (!optionFound) {
            self.hoursAgo = round([hourOptions[hourOptions.count - 1] floatValue]);
        }
    }
    
	self.mapView.delegate = self;
    
    self.mapView.calloutView = [SMCalloutView new];
    self.mapView.calloutView.delegate = self;
    self.mapView.calloutView.presentAnimation = SMCalloutAnimationStretch;
    self.windSpeedUnit = [Property getAsInteger:KEY_WIND_SPEED_UNIT].intValue;
    self.directionUnit = -1;
    
    [self refreshHours];
    [self.unitButton setTitle:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit] forState:UIControlStateNormal];

    self.feedbackView.layer.cornerRadius = 5.0;
    self.feedbackView.layer.borderWidth = 0.5;
    self.feedbackView.layer.borderColor = [UIColor colorWithRed: 0.1 green: 0.1 blue: 0.1 alpha: 1].CGColor;
    self.feedbackView.hidden = YES;
    
    self.feedbackTextView.editable = YES;
    self.feedbackTextView.font = [UIFont systemFontOfSize:14];
    self.feedbackTextView.textColor = [UIColor darkGrayColor];
    self.feedbackTextView.textAlignment = NSTextAlignmentCenter;
    self.feedbackTextView.selectable = NO;
    
    self.feedbackTextView.editable = NO;
    
    self.activityIndicator.hidden = YES;
    
    CLLocationCoordinate2D latestLocation = [LocationManager sharedInstance].latestLocation;
    
    if ([LocationManager isCoordinateValid:latestLocation]) {
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(latestLocation, 200000, 200000) animated:YES];
    }
    else {
        // TODO: set default location if user's location is unknown
    }

    self.placeholderImage = [UIImage imageNamed:@"map_placeholder.png"];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windSpeedUnitChanged) name:KEY_UNIT_CHANGED object:nil];
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if ([[[[NSLocale preferredLanguages] firstObject] substringToIndex:2] isEqualToString:@"da"]) {
        [self addLongPress];
    }
}

- (void)appDidBecomeActive:(NSNotification *)notification {
    //NSLog(@"[MapViewController] appDidBecomeActive");
    [self loadMeasurements:NO showActivityIndicator:NO];
}

-(void)appWillTerminate:(NSNotification *) notification {
    //NSLog(@"[MapViewController] appWillTerminate");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    BOOL forceReload = NO;

    // note: grid degree might have been updated by a device register call
    self.analyticsGridDegree = [[Property getAsDouble:KEY_ANALYTICS_GRID_DEGREE] doubleValue];

    WindSpeedUnit newWindSpeedUnit = [[Property getAsInteger:KEY_WIND_SPEED_UNIT] intValue];
    //NSLog(@"[MapViewController] viewWillAppear: windSpeedUnit=%u", self.windSpeedUnit);
    if (newWindSpeedUnit != self.windSpeedUnit) {
        self.windSpeedUnit = newWindSpeedUnit;
        [self.unitButton setTitle:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit] forState:UIControlStateNormal];
        forceReload = YES;
    }

    NSNumber *directionUnitNumber = [Property getAsInteger:KEY_DIRECTION_UNIT];
    NSInteger directionUnit = (directionUnitNumber) ? [directionUnitNumber doubleValue] : 0;
    if (self.directionUnit != directionUnit) {
        self.directionUnit = directionUnit;
        forceReload = YES;
    }
    
    MeasurementSession *measurementSession = [MeasurementSession MR_findFirstOrderedByAttribute:@"startTime" ascending:NO];
    if (measurementSession && measurementSession != nil && [measurementSession.measuring boolValue] == NO) {
        NSDate *newLatestLocalStartTime = measurementSession.startTime;
        if (newLatestLocalStartTime != nil && (self.latestLocalStartTime == nil || [newLatestLocalStartTime compare:self.latestLocalStartTime] == NSOrderedDescending)) {
            //NSLog(@"[MapViewController] force reload of map data");
            self.latestLocalStartTime = newLatestLocalStartTime;
            forceReload = YES;
        }
    }
    
    NSInteger currentLocalNumberOfMeasurements = [MeasurementSession MR_countOfEntities];
    if (currentLocalNumberOfMeasurements != self.latestLocalNumberOfMeasurements) {
        self.latestLocalNumberOfMeasurements = currentLocalNumberOfMeasurements;
        forceReload = YES;
    }

    [self loadMeasurements:forceReload showActivityIndicator:NO];
    [self removeOldForecasts];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:graceTimeBetweenMeasurementsRead
                                                         target:self
                                                       selector:@selector(refreshMap)
                                                       userInfo:nil
                                                        repeats:YES];

    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Map Screen"];
    }
    
    self.viewAppearedTime = [NSDate date];
    
    [self showGuideIfNeeded];
}

-(void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    [self refreshMap];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ForecastSegue"]) {
        if ([sender isKindOfClass:[ForecastAnnotation class]]) {
            ForecastAnnotation *annotation = sender;
            
            ForecastViewController *fvc = segue.destinationViewController;
            [fvc setup:annotation];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];

    [super viewWillDisappear:animated];
    if (self.refreshTimer && self.refreshTimer != nil) {
        [self.refreshTimer invalidate];
    }
}

- (void)showGuideIfNeeded {
    CGRect bounds = self.tabBarController.view.bounds;
    
    NSString *textKey;
    UIImage *icon = nil;
    CGPoint position = CGPointMake(-1, -1);
    
    BOOL hasDevice = [Property getAsBoolean:KEY_USER_HAS_WIND_METER];
    BOOL isDanish = [[[[NSLocale preferredLanguages] firstObject] substringToIndex:2] isEqualToString:@"da"];
    
    if (hasDevice && ![Property getAsBoolean:KEY_MAP_GUIDE_MEASURE_BUTTON_SHOWN_TODAY defaultValue:NO]) {
        [Property setAsBoolean:YES forKey:KEY_MAP_GUIDE_MEASURE_BUTTON_SHOWN_TODAY];
        textKey = @"KEY_MAP_GUIDE_MEASURE_BUTTON_EXPLANATION";
        position = CGPointMake(0.5, 0.97);
        icon = [UIImage imageNamed:@"MapMeasureOverlay"];
    }
    else if (isDanish && ![Property getAsBoolean:KEY_MAP_GUIDE_FORECAST_SHOWN defaultValue:NO]) {
        [Property setAsBoolean:YES forKey:KEY_MAP_GUIDE_FORECAST_SHOWN];
        textKey = @"MAP_GUIDE_FORECAST";
        icon = [UIImage imageNamed:@"ForecastPressFinger"];
    }
    else if (![Property getAsBoolean:KEY_MAP_GUIDE_MARKER_SHOWN defaultValue:NO]) {
        [Property setAsBoolean:YES forKey:KEY_MAP_GUIDE_MARKER_SHOWN];
        textKey = @"MAP_GUIDE_MARKER_EXPLANATION";
        icon = [UIImage imageNamed:@"ForecastOverlayMeasurement"];
    }
    else if (![Property getAsBoolean:KEY_MAP_GUIDE_TIME_INTERVAL_SHOWN defaultValue:NO]) {
        [Property setAsBoolean:YES forKey:KEY_MAP_GUIDE_TIME_INTERVAL_SHOWN];
        
        CGFloat x = self.hoursButton.center.x/bounds.size.width;
        CGFloat y = self.hoursButton.center.y/bounds.size.height;
        
        textKey = @"MAP_GUIDE_TIME_INTERVAL_EXPLANATION";
        position = CGPointMake(x, y);
    }
    
    if (textKey != nil) {
        [self.tabBarController.view addSubview:[[RadialOverlay alloc] initWithFrame:bounds
                                                                           position:position                                                                               text:NSLocalizedString(textKey, nil)
                                                                               icon:icon
                                                                             radius:70]];
    }
}

- (void)addLongPress {
    [self.mapView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(addPinToMap:)]];
}

- (void)addPinToMap:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D loc = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    ForecastAnnotation *annotation = [[ForecastAnnotation alloc] initWithLocation:loc];
    [[ForecastLoader shared] setup:annotation mapView:self.mapView];
    if ([Property isMixpanelEnabled]) {
        [[Mixpanel sharedInstance] track:@"Forecast added pin"];
    }
    
    [self.mapView addAnnotation:annotation];
}

- (void)removeOldForecasts {
    for (id annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[ForecastAnnotation class]]) {
            ForecastAnnotation *fcAnnotation = (ForecastAnnotation *)annotation;
            if ([[NSDate date] timeIntervalSinceDate:fcAnnotation.date] > 3600) {
                [self.mapView removeAnnotation:annotation];
            }
        }
    }
}

- (void)refreshMap {
    [self loadMeasurements:YES showActivityIndicator:NO];
}

- (void)loadMeasurements:(BOOL)ignoreGracePeriod showActivityIndicator:(BOOL)showActivityIndicator {
    if (!ignoreGracePeriod && self.lastMeasurementsRead && self.lastMeasurementsRead != nil) {
        NSTimeInterval howRecent = [self.lastMeasurementsRead timeIntervalSinceNow];
        if (fabs(howRecent) < (graceTimeBetweenMeasurementsRead - 2.0)) {
            //NSLog(@"[MapViewController] ignoring loadMeasurements due to grace period");
            return;
        }
    }
    
    self.isLoading = YES;
    
    if (self.mapView.annotations.count == 0) {
        showActivityIndicator = YES;
    }
    
    if (showActivityIndicator) {
        [self performSelector:@selector(showActivityIndicatorIfLoading) withObject:nil afterDelay:1.0];
    }
    
    [[ServerUploadManager sharedInstance] readMeasurements:self.hoursAgo retry:3 success:^(NSArray *measurements) {
//        NSLog(@"[MapViewController] read measurements");

        self.lastMeasurementsRead = [NSDate date];

        [self refreshHours];
        [self clearActivityIndicator];

        NSMutableArray *measureAnnotations = [NSMutableArray array];
        
        for (id annotation in self.mapView.annotations) {
            if ([annotation isKindOfClass:[MeasurementAnnotation class]]) {
                [measureAnnotations addObject:annotation];
                [self.mapView deselectAnnotation:annotation animated:NO];
            }
        }
        
        [self.mapView removeAnnotations:measureAnnotations];
        
        for (NSArray *measurement in measurements) {
            if (measurement.count >= 5) {
                double latitude = ((NSString *)measurement[0]).doubleValue;
                double longitude = ((NSString *)measurement[1]).doubleValue;
                NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:((NSString *)measurement[2]).doubleValue/1000.0];
                float windSpeedAvg = measurement[3] == [NSNull null] ? 0.0 : ((NSString *)measurement[3]).floatValue;
                float windSpeedMax = measurement[4] == [NSNull null] ? 0.0 : ((NSString *)measurement[4]).floatValue;

                NSNumber *windDirection = nil;
                if (measurement.count >= 6) {
                    NSNumber *value = measurement[5];
                    if (value && value != (id)[NSNull null]) {
                        windDirection = value;
                    }
                }
                
                MeasurementAnnotation *measurementAnnotation = [[MeasurementAnnotation alloc] initWithLocation:CLLocationCoordinate2DMake(latitude,longitude) startTime:startTime avgWindSpeed:windSpeedAvg maxWindSpeed:windSpeedMax windDirection:windDirection];
                [self.mapView addAnnotation:measurementAnnotation];
            }
        }
    } failure:^(NSError *error) {
//        NSLog(@"[MapViewController] Error reading measurements: %@", error);
        [self clearActivityIndicator];
//        [self showNoDataFeedbackMessage];
    }];
}

-(void)showActivityIndicatorIfLoading {
    if (self.isLoading) {
        self.activityIndicator.hidden = NO;
    }
}

-(void)clearActivityIndicator {
    self.isLoading = NO;
    if (self.activityIndicator.hidden == NO) {
        self.activityIndicator.hidden = YES;
    }
}

-(void)showFeedbackMessage:(NSString*)title message:(NSString *)message {
    if (self.feedbackView.hidden == NO) {
        return;
    }
    self.feedbackTitleLabel.text = title;
    self.feedbackTextView.text = message;
    self.feedbackView.hidden = NO;
    [self performSelector:@selector(hideFeedbackMessage) withObject:nil afterDelay:8.0];
}

-(void)hideFeedbackMessage {
    self.feedbackView.hidden = YES;
}

-(void)showNoDataFeedbackMessage {
    [self showFeedbackMessage:NSLocalizedString(@"MAP_REFRESH_ERROR_TITLE", nil) message:NSLocalizedString(@"MAP_REFRESH_ERROR_MESSAGE", nil)];
}

-(void)windSpeedUnitChanged {
    NSArray *annotations = self.mapView.annotations;
    [self.mapView removeAnnotations:annotations];
    [self.mapView addAnnotations:annotations];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    if (control.enabled) {
        [self performSegueWithIdentifier:@"ForecastSegue" sender:view.annotation];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    else if ([annotation isKindOfClass:[ForecastAnnotation class]]) {
        MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"annotation1"];
        if (pinView == nil) {
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotation1"];
            pinView.pinColor = MKPinAnnotationColorRed;
            pinView.animatesDrop = YES;
            pinView.canShowCallout = YES;
            [pinView setSelected:YES animated:YES];
            
            UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            [rightButton setImage:[UIImage imageNamed:@"Map-disclosure"] forState:UIControlStateNormal];
            rightButton.tintColor = [UIColor vaavudBlueColor];
            rightButton.enabled = NO;
            pinView.rightCalloutAccessoryView = rightButton;
            pinView.leftCalloutAccessoryView = [[ForecastCalloutView alloc] initWithFrame:CGRectMake(0, 0, 100, 70)];
        }
        
        ForecastAnnotation *fa = (ForecastAnnotation *)annotation;
        ForecastCalloutView *fc = (ForecastCalloutView *)pinView.leftCalloutAccessoryView;
        [fc setup:fa];

        UIButton *rc = (UIButton *)pinView.rightCalloutAccessoryView;
        rc.enabled = [fa hasData];
        
        return pinView;
    }
    else if ([annotation isKindOfClass:[MeasurementAnnotation class]]) {
        static NSString *measureAnnotationIdentifier = @"MeasureAnnotationIdentifier";
        
        MeasurementAnnotation *measurementAnnotation = (MeasurementAnnotation *)annotation;
        measurementAnnotation.windSpeedUnit = self.windSpeedUnit;
        
        MKAnnotationView *measureAnnotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:measureAnnotationIdentifier];
        if (measureAnnotationView == nil) {
            measureAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:measureAnnotationIdentifier];
            measureAnnotationView.canShowCallout = NO;
            measureAnnotationView.opaque = NO;
            
            UIImageView *iv = [[UIImageView alloc] init];
            iv.tag = 101;
            [measureAnnotationView addSubview:iv];
            
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
            lbl.backgroundColor = [UIColor clearColor];
            lbl.font = [UIFont systemFontOfSize:12];
            lbl.textColor = [UIColor whiteColor];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.tag = 42;
            [measureAnnotationView addSubview:lbl];
            measureAnnotationView.frame = lbl.frame;
        }
        else {
            measureAnnotationView.annotation = annotation;
        }
        
        UIImageView *iv = (UIImageView *)[measureAnnotationView viewWithTag:101];
        if (iv) {
            if (measurementAnnotation.windDirection) {
                iv.image = [UIImage imageNamed:@"MapMarkerDirection"];
                [iv sizeToFit];
                iv.transform = [UnitUtil transformForDirection:measurementAnnotation.windDirection];
            }
            else {
                iv.image = [UIImage imageNamed:@"MapMarker"];
                [iv sizeToFit];
                iv.transform = CGAffineTransformIdentity;
            }
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
            nearbyAnnotations = [NSArray array];
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
        self.measurementCalloutView.placeholderImage = self.placeholderImage;
        self.measurementCalloutView.windSpeedUnit = self.windSpeedUnit;
        self.measurementCalloutView.directionUnit = self.directionUnit;
        self.measurementCalloutView.nearbyAnnotations = nearbyAnnotations;
        self.measurementCalloutView.measurementAnnotation = view.annotation;
        [containerView addSubview:self.measurementCalloutView];
                        
        self.mapView.calloutView.contentView = containerView;
        self.mapView.calloutView.backgroundView = [CustomSMCalloutDrawnBackgroundView view];
        
        [self.mapView.calloutView presentCalloutFromRect:view.bounds
                                         inView:view
                              constrainedToView:mapView
                       permittedArrowDirections:SMCalloutArrowDirectionDown
                                       animated:!self.isSelectingFromTableView];
        
        if (self.isSelectingFromTableView) {
            [self googleAnalyticsAnnotationEvent:view.annotation withAction:@"nearby measurement touch" mixpanelTrack:@"Map Marker Selected" mixpanelSource:@"Nearby Measurements"];
        }
        else {
            [self googleAnalyticsAnnotationEvent:view.annotation withAction:@"measurement marker touch" mixpanelTrack:@"Map Marker Selected" mixpanelSource:@"Map"];
        }
        
        [MixpanelUtil addMapInteractionToProfile];
        
        self.isSelectingFromTableView = NO;
        
        if (![Property getAsBoolean:KEY_MAP_GUIDE_ZOOM_SHOWN defaultValue:NO]) {
            self.showGuideViewTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showGuideViewForZoom) userInfo:nil repeats:NO];
        }
	}
}

- (void)showGuideViewForZoom {
    if (self.measurementCalloutView) {
        if (self.showGuideViewTimer) {
            [self.showGuideViewTimer invalidate];
            self.showGuideViewTimer = nil;
        }

        [Property setAsBoolean:YES forKey:KEY_MAP_GUIDE_ZOOM_SHOWN];
        
        TabBarController *tabBarController = (TabBarController*) self.tabBarController;
        [tabBarController showCalloutGuideView:NSLocalizedString(@"MAP_GUIDE_ZOOM_TITLE", nil)
                               explanationText:NSLocalizedString(@"MAP_GUIDE_ZOOM_EXPLANATION", nil)
                                customPosition:self.measurementCalloutView.imageView.bounds
                                     withArrow:YES
                                        inView:self.mapView.calloutView];
    
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
        id<MKAnnotation> annotation = (id<MKAnnotation>)self.mapView.selectedAnnotations[0];

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

-(void)zoomToAnnotation:(MeasurementAnnotation *)annotation {
    [self.mapView deselectAnnotation:annotation animated:NO];
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(annotation.coordinate, 500, 500) animated:YES];
}

- (NSArray *)findNearbyAnnotations:(MeasurementAnnotation *)annotation {
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
    
//    NSSet *set = [self.mapView annotationsInMapRect:mapRect];
    
    NSMutableSet *set = [NSMutableSet set];
    
    for (id annotation in [self.mapView annotationsInMapRect:mapRect]) {
        if ([annotation isKindOfClass:[MeasurementAnnotation class]]) {
            [set addObject:annotation];
        }
    }
    
    if (set.count == 0) {
        return [NSArray array];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:NO];
    NSArray *sortedArray = [set sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    if (sortedArray.count > MAX_NEARBY_MEASUREMENTS) {
        NSRange range;
        range.location = 0;
        range.length = MAX_NEARBY_MEASUREMENTS;
        sortedArray = [sortedArray subarrayWithRange:range];
    }
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:sortedArray.count];
    [mutableArray addObjectsFromArray:sortedArray];
    [mutableArray removeObject:annotation];
    
    //NSLog(@"[MeasurementCalloutView] nearbyAnnotations=%@", mutableArray);
    
    return mutableArray;
}

- (IBAction)hoursButtonPushed {
    NSArray *hourOptions = [Property getAsFloatArray:KEY_HOUR_OPTIONS];
    if (hourOptions != nil && hourOptions.count > 0) {
        BOOL isOptionChanged = NO;
        for (int i = 0; i < hourOptions.count; i++) {
            int hourOptionInt = round([hourOptions[i] floatValue]);
            if (hourOptionInt > self.hoursAgo) {
                self.hoursAgo = hourOptionInt;
                [Property setAsInteger:[NSNumber numberWithInt:self.hoursAgo] forKey:KEY_MAP_HOURS];
                isOptionChanged = YES;
                break;
            }
        }
        if (!isOptionChanged) {
            self.hoursAgo = round([hourOptions[0] floatValue]);
            [Property setAsInteger:[NSNumber numberWithInt:self.hoursAgo] forKey:KEY_MAP_HOURS];
        }
    }
    
    [self refreshHours];
    [self loadMeasurements:YES showActivityIndicator:YES];
}

- (void)refreshHours {
    NSString *hoursAgo = [NSString stringWithFormat:NSLocalizedString(@"X_HOURS", nil), self.hoursAgo];
    [self.hoursButton setTitle:hoursAgo forState:UIControlStateNormal];
}

- (IBAction)unitButtonPushed {
//    self.windSpeedUnit = [UnitUtil nextWindSpeedUnit:self.windSpeedUnit];
//    [Property setAsInteger:[NSNumber numberWithInt:self.windSpeedUnit] forKey:KEY_WIND_SPEED_UNIT];
//    
//    [self.unitButton setTitle:[UnitUtil displayNameForWindSpeedUnit:self.windSpeedUnit] forState:UIControlStateNormal];
    [self windSpeedUnitChanged];
}

-(void)googleAnalyticsAnnotationEvent:(MeasurementAnnotation *)annotation
                           withAction:(NSString *)action
                        mixpanelTrack:(NSString *)track
                       mixpanelSource:(NSString *)source {
    
    if ([Property isMixpanelEnabled]) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        if (source) {
            [dictionary setObject:source forKey:@"Source"];
        }
        
        if (dictionary.count > 0) {
            [[Mixpanel sharedInstance] track:track properties:dictionary];
        }
        else {
            [[Mixpanel sharedInstance] track:track];
        }
    }
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
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
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
