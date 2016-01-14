//
//  MapViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 23/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "MapViewController.h"
#import "MeasurementAnnotation.h"
#import "CustomSMCalloutDrawnBackgroundView.h"
#import "MeasurementCalloutView.h"
#import "LocationManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Vaavud-Swift.h"
#import <VaavudSDK/VaavudSDK-Swift.h>

#include <math.h>

#define MERCATOR_RADIUS 85445659.44705395
#define MAX_GOOGLE_LEVELS 20
#define CALLOUT_ADDITIONAL_HEIGHT 42.0
#define graceTimeBetweenMeasurementsRead 300.0
#define MAX_NEARBY_MEASUREMENTS 50

@interface MapViewController ()

@property (nonatomic, weak) IBOutlet UIButton *hoursButton;
@property (nonatomic, weak) IBOutlet UIButton *unitButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic) MeasurementCalloutView *measurementCalloutView;
@property (nonatomic) NSDate *now;
@property (nonatomic) BOOL isLoading;
@property (nonatomic) BOOL isShowing;
@property (nonatomic) int hoursAgoOption;
@property (nonatomic) NSArray<NSNumber *> *hoursAgoOptions;
@property (nonatomic) double analyticsGridDegree;
@property (nonatomic) NSDate *latestLocalStartTime;
@property (nonatomic) NSTimer *refreshTimer;
@property (nonatomic) UIImage *placeholderImage;
@property (nonatomic) NSDate *viewAppearedTime;
@property (nonatomic) NSTimer *showGuideViewTimer;
@property (nonatomic) LogHelper *logHelper;
@property (nonatomic) NSMutableDictionary *currentSessions;
@property (nonatomic) NSMutableDictionary *pendingSessions;
@property (nonatomic) NSMutableDictionary *incompleteSessions;
@property (nonatomic) NSString *formatHandle;

@end

@implementation MapViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.logHelper = [[LogHelper alloc] initWithGroupName:@"Map" counters:@[@"scrolled", @"tapped-marker"]];
    }
    
    return self;
}

- (void)dealloc {
    [[VaavudFormatter shared] stopObserving:self.formatHandle];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self hideVolumeHUD];
        
    //NSLog(@"[MapViewController] viewDidLoad");
    
    self.now = [NSDate date];
    
    self.currentSessions = [[NSMutableDictionary alloc] init];
    self.pendingSessions = [[NSMutableDictionary alloc] init];
    self.incompleteSessions = [[NSMutableDictionary alloc] init];
    
    self.isLoading = NO;
    self.isSelectingFromTableView = NO;
    
    self.hoursAgoOption = 0;
    self.hoursAgoOptions = @[@3, @6, @12, @24];
    
	self.mapView.delegate = self;
    
    self.mapView.calloutView = [SMCalloutView new];
    self.mapView.calloutView.delegate = self;
    self.mapView.calloutView.presentAnimation = SMCalloutAnimationStretch;
    
    [self refreshHoursButton];
    [self refreshUnitButton];
    
    self.activityIndicator.hidden = YES;
    
    CLLocationCoordinate2D location = [LocationManager sharedInstance].latestLocation;
    
    if (![LocationManager isCoordinateValid:location]) {
        location = [LocationManager sharedInstance].storedLocation;
    }
    
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(location, 200000, 200000) animated:YES];

    self.placeholderImage = [UIImage imageNamed:@"map_placeholder.png"];
    
    self.formatHandle = [[VaavudFormatter shared] observeUnitChange:^{ [self unitChanged]; }];
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if ([self isDanish]) {
        [self addLongPress];
    }
    
    [self setupFirebase];
}

- (BOOL)isDanish {
    return NO; // Fixme
    return [[[[NSLocale preferredLanguages] firstObject] substringToIndex:2] isEqualToString:@"da"];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    self.isShowing  = YES;
    [self refreshPendingAnnotations];

    [self removeOldForecasts];
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:3600
                                                         target:self
                                                       selector:@selector(removeOldSessions)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.viewAppearedTime = [NSDate date];
    
    [self showGuideIfNeeded];
    
    [self.logHelper began:@{}];
    [LogHelper increaseUserProperty:@"Use-Map-Count"];
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

    [self.refreshTimer invalidate];
    [self hideCallout];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.isShowing  = NO;
    [self.logHelper ended:@{}];
}

- (void)showGuideIfNeeded {
    CGRect bounds = self.tabBarController.view.bounds;
    
    NSString *textKey;
    UIImage *icon = nil;
    CGPoint position = CGPointMake(-1, -1);
    
//    BOOL hasDevice = [Property getAsBoolean:KEY_USER_HAS_WIND_METER];
    
//    if (hasDevice && ![Property getAsBoolean:KEY_MAP_GUIDE_MEASURE_BUTTON_SHOWN_TODAY defaultValue:NO]) {
//        [Property setAsBoolean:YES forKey:KEY_MAP_GUIDE_MEASURE_BUTTON_SHOWN_TODAY];
        textKey = @"KEY_MAP_GUIDE_MEASURE_BUTTON_EXPLANATION";
        position = CGPointMake(0.5, 0.97);
        icon = [UIImage imageNamed:@"MapMeasureOverlay"];
//    }
//    else if ([self isDanish] && ![Property getAsBoolean:KEY_MAP_GUIDE_FORECAST_SHOWN defaultValue:NO]) {
//        [Property setAsBoolean:YES forKey:KEY_MAP_GUIDE_FORECAST_SHOWN];
//        textKey = @"MAP_GUIDE_FORECAST";
//        icon = [UIImage imageNamed:@"ForecastPressFinger"];
//    }
//    else if (![Property getAsBoolean:KEY_MAP_GUIDE_MARKER_SHOWN defaultValue:NO]) {
//        [Property setAsBoolean:YES forKey:KEY_MAP_GUIDE_MARKER_SHOWN];
//        textKey = @"MAP_GUIDE_MARKER_EXPLANATION";
//        icon = [UIImage imageNamed:@"ForecastOverlayMeasurement"];
//    }
//    else if (![Property getAsBoolean:KEY_MAP_GUIDE_TIME_INTERVAL_SHOWN defaultValue:NO]) {
//        [Property setAsBoolean:YES forKey:KEY_MAP_GUIDE_TIME_INTERVAL_SHOWN];
//        
//        CGFloat x = self.hoursButton.center.x/bounds.size.width;
//        CGFloat y = self.hoursButton.center.y/bounds.size.height;
//        
//        textKey = @"MAP_GUIDE_TIME_INTERVAL_EXPLANATION";
//        position = CGPointMake(x, y);
//    }
    
    if (textKey != nil) {
        [self.tabBarController.view addSubview:[[RadialOverlay alloc] initWithFrame:bounds
                                                                           position:position
                                                                               text:NSLocalizedString(textKey, nil)
                                                                               icon:icon
                                                                             radius:70]];
    }
}

- (void)addLongPress {
    [self.mapView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)]];
    [self.logHelper log:@"Can-Add-Forecast-Pin" properties:@{}];
    [LogHelper increaseUserProperty:@"Use-Forecast-Count"];
}

- (void)longPressed:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D loc = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];

    [self.logHelper log:@"Added-Forecast-Pin" properties:@{}];

    [self addPin:loc];
}

- (void)addPin:(CLLocationCoordinate2D)loc {
    ForecastAnnotation *annotation = [[ForecastAnnotation alloc] initWithLocation:loc];

    [[ForecastLoader shared] setup:annotation mapView:self.mapView];
    
    [self.mapView addAnnotation:annotation];
    [self.mapView selectAnnotation:annotation animated:YES];
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
    
    [self refreshEmptyState];
}

- (void)refreshEmptyState {
    if (![self isDanish]) {
        return;
    }

    for (id annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[ForecastAnnotation class]]) {
            return;
        }
    }
    
    [self addPin:[LocationManager sharedInstance].storedLocation];
}

//- (BOOL)annotationAlreadyExistsAtLatitude:(CLLocationDegrees)lat longitude:(CLLocationDegrees)lon {
//    if (self.view == nil) {
//        return NO;
//    }
//    
//    for (id<MKAnnotation> annotation in self.mapView.annotations) {
//        if ([annotation isKindOfClass:[MeasurementAnnotation class]]) {
//            if (lat == [annotation coordinate].latitude && lon == [annotation coordinate].longitude ) {
//                return YES;
//            }
//        }
//    }
//
//    return NO;
//}

//-(void)removeOldAnnotations {
//    NSMutableArray *oldAnnotations = [NSMutableArray array];
//    
//    for (id annotation in self.mapView.annotations) {
//        if ([annotation isKindOfClass:[MeasurementAnnotation class]]) {
//            MeasurementAnnotation *measurementAnnotation = annotation;
//            if ([self.lastMeasurementsRead timeIntervalSinceDate:measurementAnnotation.startTime]) {
//                [oldAnnotations addObject:measurementAnnotation];
//                [self.mapView deselectAnnotation:annotation animated:NO];
//            }
//        }
//    }
//    
//    [self.mapView removeAnnotations:oldAnnotations];
//}

- (void)workingWithIncompleteAnnotations:(FDataSnapshot *)data {
    if (data.value[@"location"] == nil || self.currentSessions[data.key] != nil ) {
        return;
    }
    
    if ([NSDate dateWithTimeIntervalSinceNow:-3600].ms > data.value[@"timeStart"]){
        return;
    }
    
    NSLog(@"changing %@ session", data.key);
    
    if (data.value[@"timeEnd"] != nil) {
        MeasurementAnnotation *annotation = self.incompleteSessions[data.key];
        MKAnnotationView *annotationView = [self.mapView viewForAnnotation: annotation];
        annotation.isFinished = YES;
        
        [UIView animateWithDuration:0.3 animations:^{
            [self updateAnnotationView:annotationView];
        }];
        
        [self addAnnotationToStack:annotation  sessionKey:data.key];
    }
    else {
        if (self.incompleteSessions[data.key] == nil){
            NSDictionary *loctation = ((NSDictionary *)data.value[@"location"]);
            
            CLLocationDegrees latitude = ((NSString *)loctation[@"lat"]).doubleValue;
            CLLocationDegrees longitude = ((NSString *)loctation[@"lon"]).doubleValue;
            
            NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:((NSString *) data.value[@"timeStart"]).doubleValue/1000.0];
            float windSpeedAvg = data.value[@"windMean"] == [NSNull null] ? 0.0 : ((NSString *) data.value[@"windMean"]).floatValue;
            float windSpeedMax = data.value[@"windMax"] == [NSNull null] ? 0.0 : ((NSString *) data.value[@"windMax"]).floatValue;
            
            NSNumber *windDirection = nil;
            NSNumber *value = data.value[@"windDirection"];
            if (value && value != (id)[NSNull null]) {
                windDirection = value;
            }
            
            MeasurementAnnotation *measurementAnnotation = [[MeasurementAnnotation alloc] initWithLocation:CLLocationCoordinate2DMake(latitude,longitude) sessionKey:data.key startTime:startTime avgWindSpeed:windSpeedAvg maxWindSpeed:windSpeedMax windDirection:windDirection];
            
            if (self.isShowing) {
                [self.mapView addAnnotation:measurementAnnotation];
            }
            
            self.incompleteSessions[data.key] = measurementAnnotation;
        }
        else {
            MeasurementAnnotation *annotation = self.incompleteSessions[data.key];
            
            NSDictionary *loctation = ((NSDictionary *)data.value[@"location"]);
            
            CLLocationDegrees latitude = ((NSString *)loctation[@"lat"]).doubleValue;
            CLLocationDegrees longitude = ((NSString *)loctation[@"lon"]).doubleValue;
            
            MKAnnotationView *annotationView = [self.mapView viewForAnnotation:annotation];
            MeasurementAnnotation *measurementAnnotation = (MeasurementAnnotation *)annotationView.annotation;
            
            float windSpeedAvg = data.value[@"windMean"] == [NSNull null] ? 0.0 : ((NSString *) data.value[@"windMean"]).floatValue;
            float windSpeedMax = data.value[@"windMax"] == [NSNull null] ? 0.0 : ((NSString *) data.value[@"windMax"]).floatValue;
            
            NSNumber *windDirection = nil;
            NSNumber *value = data.value[@"windDirection"];
            if (value && value != (id)[NSNull null]) {
                windDirection = value;
            }
            
            measurementAnnotation.windDirection = value;
            measurementAnnotation.maxWindSpeed = windSpeedMax;
            measurementAnnotation.avgWindSpeed = windSpeedAvg;
            annotationView.annotation = measurementAnnotation;

            if (!self.isShowing){
                return;
            }
            
            annotation.isFinished = NO;
            
            [UIView animateWithDuration:0.3 animations:^{
                annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
                [self updateAnnotationView: annotationView];
            }];
        }
    }
}

- (void)addAnnotationToStack:(MeasurementAnnotation *)annotation sessionKey:(NSString *)key {
    if (self.isShowing) {
        self.currentSessions[key] = annotation;
    }
    else {
        self.pendingSessions[key] = annotation;
    }
}

- (void)addAnnotation:(FDataSnapshot *)data {
    if (data.value[@"location"] == nil ) {
        return;
    }
    
    if (data.value[@"timeEnd"] == nil) {
        if ([NSDate dateWithTimeIntervalSinceNow:-3600].ms > data.value[@"timeStart"]){
            //NSLog(@"session too old %@ with no time end", data.key);
            return;
        }
    }
    
    if (self.currentSessions[data.key] || self.pendingSessions[data.key]) {
        return;
    }
    
    NSLog(@"adding new sessions  %@  ", data.key);
        
    NSDictionary *loctation = ((NSDictionary *)data.value[@"location"]);
        
    CLLocationDegrees latitude = ((NSString *)loctation[@"lat"]).doubleValue;
    CLLocationDegrees longitude = ((NSString *)loctation[@"lon"]).doubleValue;
        
    NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:((NSString *)data.value[@"timeStart"]).doubleValue/1000.0];
    float windSpeedAvg = data.value[@"windMean"] == [NSNull null] ? 0.0 : ((NSString *)data.value[@"windMean"]).floatValue;
    float windSpeedMax = data.value[@"windMax"] == [NSNull null] ? 0.0 : ((NSString *)data.value[@"windMax"]).floatValue;
        
    NSNumber *windDirection = nil;
    NSNumber *value = data.value[@"windDirection"];
    if (value && value != (id)[NSNull null]) {
        windDirection = value;
    }
        
    MeasurementAnnotation *measurementAnnotation = [[MeasurementAnnotation alloc] initWithLocation:CLLocationCoordinate2DMake(latitude,longitude) sessionKey: data.key startTime:startTime avgWindSpeed:windSpeedAvg maxWindSpeed:windSpeedMax windDirection:windDirection];
    
    measurementAnnotation.isFinished = YES;
    
    [self.mapView addAnnotation:measurementAnnotation];
    [self addAnnotationToStack:measurementAnnotation sessionKey:data.key];
}

- (void)refreshPendingAnnotations {
    for (NSString* key in self.pendingSessions) {
        MeasurementAnnotation *mesAnnotation = (MeasurementAnnotation *)self.pendingSessions[key];
        
        if(mesAnnotation != nil){
            [self.mapView addAnnotation:mesAnnotation];
            self.currentSessions[key] = mesAnnotation;
            self.pendingSessions[key] = nil;
            
            NSLog(@"adding pending  %@ session ", key);
        }
    }
}

- (void)removeOldSessions {
    for (NSString* key in self.currentSessions) {
        MeasurementAnnotation *mesAnnotation = (MeasurementAnnotation *)self.currentSessions[key];
        
        if (mesAnnotation.startTime.ms < [NSDate dateWithTimeIntervalSinceNow:-24*60*60].ms) {
            [self.mapView removeAnnotation:mesAnnotation];
            self.currentSessions[key] = nil;
        }
    }
}

- (void)setupFirebase {
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://vaavud-core-demo.firebaseio.com/session/"];
    
    NSNumber *currentTime = [NSDate dateWithTimeIntervalSinceNow:-24*60*60].ms;
    
    [[[ref queryOrderedByChild:@"timeStart"] queryStartingAtValue: currentTime]
     observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
         if (self.currentSessions[snapshot.key]) {
             MeasurementAnnotation *mesAnnotation = (MeasurementAnnotation *)self.currentSessions[snapshot.key];
             
             if (mesAnnotation != nil){
                 [self.mapView removeAnnotation:mesAnnotation];
                 self.currentSessions[snapshot.key] = nil;
             }
         }
     }];
    
    [[[ref queryOrderedByChild:@"timeStart"] queryStartingAtValue: currentTime]
     observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
         [self addAnnotation: snapshot];
     }];
    
    NSLog(@"current time %@ session ", currentTime);
    
    [[[ref queryOrderedByChild:@"timeStart"] queryStartingAtValue: currentTime]
     observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
         [self workingWithIncompleteAnnotations: snapshot];
         //[self addAnnotation: snapshot];
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
        
        [self updateAnnotationView:measureAnnotationView];
        
        return measureAnnotationView;
    }
    
    return nil;
}

-(void)updateAnnotationView:(MKAnnotationView *)annotationView {
    MeasurementAnnotation *measurementAnnotation = (MeasurementAnnotation *)annotationView.annotation;
    
    UIImageView *iv = (UIImageView *)[annotationView viewWithTag:101];
    if (iv) {
        if (measurementAnnotation.windDirection) {
            iv.image = [UIImage imageNamed: measurementAnnotation.isFinished ? @"MapMarkerDirection" : @"MapMarkerDirectionBlue"];
            [iv sizeToFit];
            iv.transform = [VaavudFormatter transformWithDirection:measurementAnnotation.windDirection.floatValue];
        }
        else {
            iv.image = [UIImage imageNamed: measurementAnnotation.isFinished ? @"MapMarker" : @"MapMarkerBlue"];
            [iv sizeToFit];
            iv.transform = CGAffineTransformIdentity;
        }
    }
    
    UILabel *lbl = (UILabel *)[annotationView viewWithTag:42];
    lbl.text = measurementAnnotation.title;
    
    annotationView.hidden = [self isTooOld:measurementAnnotation.startTime];
}

-(BOOL)isTooOld:(NSDate *)time {
    NSTimeInterval secondsAgo = self.hoursAgoOptions[self.hoursAgoOption].intValue*3600;
    return [self.now timeIntervalSinceDate:time] > secondsAgo;
}

-(void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    [self.logHelper increase:@"scrolled"];
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

        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"MeasurementCalloutView" owner:self options:nil];
        self.measurementCalloutView = (MeasurementCalloutView*) [topLevelObjects objectAtIndex:0];
        self.measurementCalloutView.frame = CGRectMake(0, 0, 280, height);
        self.measurementCalloutView.mapViewController = self;
        self.measurementCalloutView.placeholderImage = self.placeholderImage;
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
            [self.logHelper log:@"Tapped-Nearby" properties:@{}];
        }
        else {
            [self.logHelper log:@"Tapped-Marker" properties:@{}];
            [self.logHelper increase:@"tapped-marker"];
        }
        
        self.isSelectingFromTableView = NO;
	}
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
	if ([view.annotation isKindOfClass:[MeasurementAnnotation class]]) {
        [self hideCallout];
    }
}

-(void)hideCallout {
    if (self.mapView.calloutView.window) {
        [self.mapView.calloutView dismissCalloutAnimated:NO];
        self.measurementCalloutView = nil;
    }
}

- (NSTimeInterval)calloutView:(SMCalloutView *)theCalloutView delayForRepositionWithSize:(CGSize)offset {
    if (self.mapView.selectedAnnotations.count > 0) {
        id<MKAnnotation> annotation = (id<MKAnnotation>)self.mapView.selectedAnnotations[0];

        // TODO: this is an approximation that will not necessarily hold at target latitude
        CGFloat pixelsPerDegreeLat = self.mapView.frame.size.height / self.mapView.region.span.latitudeDelta;
        CGFloat pixelsPerDegreeLon = self.mapView.frame.size.width / self.mapView.region.span.longitudeDelta;
        
        CGFloat topLayoutGuide = self.topLayoutGuide.length;
        CLLocationDegrees longitudinalShift = -(offset.width / pixelsPerDegreeLon);
        
        float calloutHeight = (self.measurementCalloutView ? self.measurementCalloutView.frame.size.height : 0.0) + CALLOUT_ADDITIONAL_HEIGHT;
        //NSLog(@"calloutHeight=%f", calloutHeight);
        float ypixelShift = (self.mapView.frame.size.height / 2.0) - topLayoutGuide - calloutHeight;
        CLLocationDegrees latitudinalShift = ypixelShift / pixelsPerDegreeLat;
        CGFloat lat = annotation.coordinate.latitude - latitudinalShift;
        
        CGFloat lon = self.mapView.region.center.longitude + longitudinalShift;
        CLLocationCoordinate2D newCenterCoordinate = (CLLocationCoordinate2D){lat, lon};
        if (fabs(newCenterCoordinate.latitude) <= 90 && fabs(newCenterCoordinate.longitude) <= 180) {
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
    
    NSMutableSet *set = [NSMutableSet set];
    
    for (id annotation in [self.mapView annotationsInMapRect:mapRect]) {
        if ([annotation isKindOfClass:[MeasurementAnnotation class]]) {
            MeasurementAnnotation *ma = (MeasurementAnnotation *)annotation;

            if (![self isTooOld:ma.startTime]) {
                [set addObject:annotation];
            }
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
    [self hideCallout];
    self.hoursAgoOption = (self.hoursAgoOption + 1) % self.hoursAgoOptions.count;
    
    [self refreshHoursButton];
    [self refreshMeasurementAnnotations];
}

- (void)refreshHoursButton {
    int hoursAgo = self.hoursAgoOptions[self.hoursAgoOption].intValue;
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"X_HOURS", nil), hoursAgo];
    [self.hoursButton setTitle:title forState:UIControlStateNormal];
}

- (void)unitChanged {
    [self refreshUnitButton];
    [self refreshMeasurementAnnotations];
}

- (void)refreshUnitButton {
    NSString *title = [[VaavudFormatter shared] speedUnitLocalName];
    [self.unitButton setTitle:title forState:UIControlStateNormal];
}

- (void)refreshMeasurementAnnotations {
    self.now = [NSDate date];
    for (id annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MeasurementAnnotation class]]) {
            [self updateAnnotationView:[self.mapView viewForAnnotation:annotation]];
        }
    }
}

- (IBAction)unitButtonPushed {
    [self hideCallout];
    [[VaavudFormatter shared] nextSpeedUnit];
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
