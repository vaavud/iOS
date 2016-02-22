//
//  MapViewController.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 23/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "MapViewController.h"
#import "CustomSMCalloutDrawnBackgroundView.h"
#import "MeasurementCalloutView.h"
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
@property (nonatomic) BOOL isShowing;
@property (nonatomic) BOOL didScroll;
@property (nonatomic) int hoursAgoOption;
@property (nonatomic) NSArray<NSNumber *> *hoursAgoOptions;
@property (nonatomic) double analyticsGridDegree;
@property (nonatomic) NSTimer *refreshTimer;
@property (nonatomic) UIImage *placeholderImage;
@property (nonatomic) NSTimer *showGuideViewTimer;
@property (nonatomic) LogHelper *logHelper;
@property (nonatomic) NSMutableDictionary *currentSessions;
@property (nonatomic) NSString *formatHandle;
@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic) BOOL pendingNotification;
@property (nonatomic) NSString* pendingNotificationKey;

@property (nonatomic) Firebase *firebase;

@end

@implementation MapViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.logHelper = [[LogHelper alloc] initWithGroupName:@"Map" counters:@[@"scrolled", @"tapped-marker"]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(receiveTestNotification:)
        name:@"PushNotification"
        object:nil];
    
    return self;
}

- (void)dealloc {
    [[VaavudFormatter shared] stopObserving:self.formatHandle];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self hideVolumeHUD];
    
    self.firebase = [[Firebase alloc] initWithUrl:[AuthorizationController getFirebaseUrl]];
    
    self.currentSessions = [[NSMutableDictionary alloc] init];
    
    self.didScroll = NO;
    self.isSelectingFromTableView = NO;
    
    self.hoursAgoOption = 3;
    self.hoursAgoOptions = @[@3, @6, @12, @24];
    
    self.mapView.delegate = self;
    
    self.mapView.calloutView = [SMCalloutView new];
    self.mapView.calloutView.delegate = self;
    self.mapView.calloutView.presentAnimation = SMCalloutAnimationStretch;
    
    [self refreshHoursButton];
    [self refreshUnitButton];
    
    self.activityIndicator.hidden = YES;
    
    [self setupMapPosition];
    
    self.placeholderImage = [UIImage imageNamed:@"map_placeholder.png"];
    
    __weak typeof(self) weakSelf = self;

    self.formatHandle = [[VaavudFormatter shared] observeUnitChange:^{ [weakSelf unitChanged]; }];
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if ([self isDanish]) {
        [self addLongPress];
    }
    
    [self setupFirebase];
    [self setupSettingFirebase];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    self.isShowing = YES;
    [self refreshAnnotations];
    [self removeOldForecasts];
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:600
                                                         target:self
                                                       selector:@selector(refresh)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.logHelper began:@{}];
    [LogHelper increaseUserProperty:@"Use-Map-Count"];
    
    
    if (self.pendingNotification) {
        self.pendingNotification = NO;
        self.tabBarController.tabBar.items[1].badgeValue = 0;
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showSessionFromNotification: self.pendingNotificationKey];
        });
        
        
        
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
    self.isShowing = NO;
    [self refreshAnnotations];
    
    [self.logHelper ended:@{}];
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

// Notifications

- (void)receiveTestNotification:(NSNotification *) notification {
    // [notification name] should always be @"TestNotification"
    // unless you use this method for observation of other notifications
    // as well.
    
    if ([[notification name] isEqualToString:@"PushNotification"]){
        NSLog (@"Successfully received the test notification!");
        //self.isFromNotification = YES;
        
//        if let tabArray = tabBar.items {
//            tabArray[1].badgeValue = "1"
//        }
        
        
        NSDictionary *userInfo = notification.object;
        NSString *sessionId = [userInfo objectForKey:@"sessionKey"];
        
        
        if (self.isShowing){
            [self showSessionFromNotification: sessionId];
        }
        else {
            self.pendingNotification = YES;
            self.pendingNotificationKey = sessionId;
        }
    }
}




-(void) showSessionFromNotification:(NSString *) sessionKey {
    
    NSLog(@"show Notification");
    
    MeasurementAnnotation *sessionNotification = (MeasurementAnnotation *)self.currentSessions[sessionKey];
    [self.mapView viewForAnnotation:sessionNotification].alpha = 0;
    
    MKCoordinateRegion mapRegion;
    mapRegion.center = sessionNotification.coordinate;
    mapRegion.span.latitudeDelta = 0.2;
    mapRegion.span.longitudeDelta = 0.2;
    
    
    [self.mapView setRegion:mapRegion animated: YES];
    
    
    [UIView animateWithDuration:0.9 delay:0.2 options: UIViewAnimationOptionAutoreverse animations:^{
        [self.mapView viewForAnnotation:sessionNotification].alpha = 1;
    } completion:nil];
    
}





// Location Manager Delegate

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocationCoordinate2D location = locations[locations.count - 1].coordinate;
    if (CLLocationCoordinate2DIsValid(location)) {
        [self gotValidLocation:location];
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Map view location manager failed");
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status != kCLAuthorizationStatusRestricted && status != kCLAuthorizationStatusDenied && status != kCLAuthorizationStatusNotDetermined) {
        [self.locationManager startUpdatingLocation];
    }
}

// Private Methods

-(CLLocationCoordinate2D)storedLocation {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CLLocationDegrees lat = [defaults doubleForKey:KEY_STORED_LOCATION_LAT];
    CLLocationDegrees lon = [defaults doubleForKey:KEY_STORED_LOCATION_LON];
    
    if (lat == 0 && lon == 0) {
        return CLLocationCoordinate2DMake(55.676111, 12.568333);
    }
    
    return CLLocationCoordinate2DMake(lat, lon);
}

- (void)setupFirebase {
    Firebase *ref = [self.firebase childByAppendingPath:@"session"];
    
    NSNumber *dayAgo = [NSDate dateWithTimeIntervalSinceNow:-24*60*60].ms;
    
    __weak typeof(self) weakSelf = self;
    
    [[[ref queryOrderedByChild:@"timeStart"] queryStartingAtValue:dayAgo] observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snap) {
        MeasurementAnnotation *ma = (MeasurementAnnotation *)weakSelf.currentSessions[snap.key];
        if (ma != nil) {
            [weakSelf.mapView removeAnnotation:ma];
            [weakSelf.currentSessions removeObjectForKey:snap.key];
        }
    }];
    
    [[[ref queryOrderedByChild:@"timeStart"] queryStartingAtValue:dayAgo] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snap) {
        [weakSelf updateAnnotation:snap];
    }];
    
    [[[ref queryOrderedByChild:@"timeStart"] queryStartingAtValue:dayAgo] observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snap) {
        [weakSelf updateAnnotation:snap];
    }];
}

-(void)gotValidLocation:(CLLocationCoordinate2D)location {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:location.latitude forKey:KEY_STORED_LOCATION_LAT];
    [defaults setDouble:location.longitude forKey:KEY_STORED_LOCATION_LON];
    [defaults synchronize];
    
    if (!self.didScroll) {
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(location, 200000, 200000) animated:YES];
    }
    
    self.locationManager.delegate = nil;
    self.locationManager = nil;
}

-(void)setupMapPosition {
    
//    NSOperatingSystemVersion ios9_0_0 = (NSOperatingSystemVersion){9, 0, 0};
//    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios9_0_0]) {
//        
//        
//    }
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance([self storedLocation], 200000, 200000) animated:YES];
    
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusRestricted || authorizationStatus == kCLAuthorizationStatusDenied) {
        return;
    }
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    else if (authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    else if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager requestLocation];
    }
}

- (BOOL)isDanish {
    return [[[[NSLocale preferredLanguages] firstObject] substringToIndex:2] isEqualToString:@"da"];
}

-(void)setupSettingFirebase {
    Firebase *setting = [[[[self.firebase childByAppendingPath:@"user"] childByAppendingPath:[AuthorizationController shared].uid] childByAppendingPath:@"setting"] childByAppendingPath:@"ios"];
    
    [setting observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if (![snapshot.value isKindOfClass:[NSDictionary class]]) {
            return;
        }
        
        NSDictionary *dict = (NSDictionary *)snapshot.value;
        
        CGRect bounds = self.tabBarController.view.bounds;
        NSString *textKey;
        UIImage *icon = nil;
        CGPoint position = CGPointMake(-1, -1);
        
        if (![dict[@"mapGuideMeasurePopupShown"] boolValue]) {
            [[setting childByAppendingPath:@"mapGuideMeasurePopupShown"] setValue:@YES];
            textKey = @"KEY_MAP_GUIDE_MEASURE_BUTTON_EXPLANATION";
            position = CGPointMake(0.5, 0.97);
            icon = [UIImage imageNamed:@"MapMeasureOverlay"];
        }
        else if ([self isDanish] && ![dict[@"mapGuideForecastShown"] boolValue]) {
            [[setting childByAppendingPath:@"mapGuideForecastShown"] setValue:@YES];
            textKey = @"MAP_GUIDE_FORECAST";
            icon = [UIImage imageNamed:@"ForecastPressFinger"];
        }
        else if (![dict[@"mapGuideMarkerShown"] boolValue]) {
            [[setting childByAppendingPath:@"mapGuideMarkerShown"] setValue:@YES];
            textKey = @"MAP_GUIDE_MARKER_EXPLANATION";
            icon = [UIImage imageNamed:@"ForecastOverlayMeasurement"];
        }
        else if (![dict[@"mapGuideTimeIntervalShown"] boolValue]) {
            [[setting childByAppendingPath:@"mapGuideTimeIntervalShown"] setValue:@YES];
            CGFloat x = self.hoursButton.center.x/bounds.size.width;
            CGFloat y = self.hoursButton.center.y/bounds.size.height;
            
            textKey = @"MAP_GUIDE_TIME_INTERVAL_EXPLANATION";
            position = CGPointMake(x, y);
        }
        
        if (textKey != nil) {
            [self.tabBarController.view addSubview:[[RadialOverlay alloc] initWithFrame:bounds
                                                                               position:position
                                                                                   text:NSLocalizedString(textKey, nil)
                                                                                   icon:icon
                                                                                 radius:70]];
        }
    }];
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
    [self addPin:[self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView]];
    [self.logHelper log:@"Added-Forecast-Pin" properties:@{}];
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
    
    [self addPin:[self storedLocation]];
}

- (void)updateAnnotation:(FDataSnapshot *)data {
    if (data.value[@"location"] == nil ) { return; }
    
    NSDictionary *loctation = ((NSDictionary *)data.value[@"location"]);
    CLLocationDegrees latitude = ((NSString *)loctation[@"lat"]).doubleValue;
    CLLocationDegrees longitude = ((NSString *)loctation[@"lon"]).doubleValue;
    
    if (latitude == 0 || longitude == 0) { return; }

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    
    if (!CLLocationCoordinate2DIsValid(coordinate)) { return; }

    NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:((NSString *)data.value[@"timeStart"]).doubleValue/1000.0];
    float windSpeedAvg = data.value[@"windMean"] == [NSNull null] ? 0.0 : ((NSString *)data.value[@"windMean"]).floatValue;
    float windSpeedMax = data.value[@"windMax"] == [NSNull null] ? 0.0 : ((NSString *)data.value[@"windMax"]).floatValue;

    NSNumber *windDirection = nil;
    NSNumber *value = data.value[@"windDirection"];
    if (value && value != (id)[NSNull null]) {
        windDirection = value;
    }

    MeasurementAnnotation *ma = self.currentSessions[data.key];
    
    if (ma == nil) {
        ma = [[MeasurementAnnotation alloc] initWithStartTime:startTime];
        ma.isOnMap = NO;
        self.currentSessions[data.key] = ma;
    }
    
    ma.coordinate = coordinate;
    ma.avgWindSpeed = windSpeedAvg;
    ma.maxWindSpeed = windSpeedMax;
    ma.windDirection = windDirection;
    ma.isFinished = data.value[@"timeEnd"] != nil;
    
    [self refreshAnnotation:ma];
    
    MKAnnotationView *view = [self.mapView viewForAnnotation:ma];
    if (view != nil) {
        [UIView animateWithDuration:0.3 animations:^{
            [self updateAnnotationView:view];
        }];
    }
}

-(void)refreshAnnotations {
    for (MeasurementAnnotation *ma in self.currentSessions.allValues) {
        [self refreshAnnotation:ma];
    }
}

-(void)refreshAnnotation:(MeasurementAnnotation *)ma {
    NSDate *now = [NSDate date];
    ma.isFinished = ma.isFinished || [now timeIntervalSinceDate:ma.startTime] > 600;
    
    BOOL isOld = [self isTooOld:ma.startTime current:now];
    
    if (ma.isOnMap && isOld) {
        [self.mapView removeAnnotation:ma];
        ma.isOnMap = NO;
    }
    else if (!ma.isOnMap && !isOld && self.isShowing) {
        [self.mapView addAnnotation:ma];
        ma.isOnMap = YES;
    }
}

-(void)updateAnnotationViews {
    for (MeasurementAnnotation *ma in self.mapView.annotations) {
        MKAnnotationView *view = [self.mapView viewForAnnotation:ma];
        if (view != nil) {
            [UIView animateWithDuration:0.3 animations:^{
                [self updateAnnotationView:view];
            }];
        }
    }
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
}

-(void)refresh {
    [self removeOldSessions];
    [self refreshAnnotations];
    [self updateAnnotationViews];
    [self removeOldForecasts];
}

- (void)removeOldSessions {
    for (NSString *key in self.currentSessions.allKeys) {
        MeasurementAnnotation *ma = (MeasurementAnnotation *)self.currentSessions[key];
        
        if (ma.startTime.ms < [NSDate dateWithTimeIntervalSinceNow:-24*60*60].ms) {
            [self.mapView removeAnnotation:ma];
            [self.currentSessions removeObjectForKey:key];
        }
    }
}

-(BOOL)isTooOld:(NSDate *)time current:(NSDate *)current {
    NSTimeInterval secondsAgo = self.hoursAgoOptions[self.hoursAgoOption].intValue*3600;
    return [current timeIntervalSinceDate:time] > secondsAgo;
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    if (control.enabled) {
        [self performSegueWithIdentifier:@"ForecastSegue" sender:view.annotation];
    }
}

// Map View Delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
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

-(void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    [self.logHelper increase:@"scrolled"];
    self.didScroll = YES;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MeasurementAnnotation class]]) {
        NSArray *nearbyAnnotations;
        
        //NSLog(@"zoomLevel=%f", [self.mapView getZoomLevel]);
        
        if ([self.mapView getZoomLevel] <= 7) {
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
        
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, height)];
        
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"MeasurementCalloutView" owner:self options:nil];
        self.measurementCalloutView = (MeasurementCalloutView *)[topLevelObjects objectAtIndex:0];
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
    else if ([view.annotation isKindOfClass:[ForecastAnnotation class]]) {
        [self reloadAnnotationView:view];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MeasurementAnnotation class]]) {
        [self hideCallout];
    }
}

-(void)reloadForecastCallouts {
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[ForecastAnnotation class]]) {
            MKAnnotationView *view = [self.mapView viewForAnnotation:annotation];
            if (view) {
                [self reloadAnnotationView:view];
            }
        }
    }
}

-(void)reloadAnnotationView:(MKAnnotationView *)view {
    if ([view.leftCalloutAccessoryView isKindOfClass:[ForecastCalloutView class]]) {
        [(ForecastCalloutView *)view.leftCalloutAccessoryView reload];
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
    
    NSDate *current = [NSDate date];
    
    for (id annotation in [self.mapView annotationsInMapRect:mapRect]) {
        if ([annotation isKindOfClass:[MeasurementAnnotation class]]) {
            MeasurementAnnotation *ma = (MeasurementAnnotation *)annotation;
            
            if (![self isTooOld:ma.startTime current:current]) {
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

// User Actions

- (IBAction)hoursButtonPushed {
    [self hideCallout];
    self.hoursAgoOption = (self.hoursAgoOption + 1) % self.hoursAgoOptions.count;
    
    [self refreshHoursButton];
    [self refreshAnnotations];
}

- (IBAction)unitButtonPushed {
    [self hideCallout];
    [[VaavudFormatter shared] nextSpeedUnit];
}

- (void)refreshHoursButton {
    int hoursAgo = self.hoursAgoOptions[self.hoursAgoOption].intValue;
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"X_HOURS", nil), hoursAgo];
    [self.hoursButton setTitle:title forState:UIControlStateNormal];
}

- (void)unitChanged {
    [self refreshUnitButton];
    [self updateAnnotationViews];
    
    [self reloadForecastCallouts];
}

- (void)refreshUnitButton {
    NSString *title = [[VaavudFormatter shared] speedUnitLocalName];
    [self.unitButton setTitle:title forState:UIControlStateNormal];
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
