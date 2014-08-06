//
//  MapViewController.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 23/09/2013.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "SMCalloutView.h"
#import "MeasurementSession+Util.h"
#import "MeasurementAnnotation.h"
#import "TabBarController.h"

@interface CustomMapView : MKMapView

@property (nonatomic) SMCalloutView *calloutView;
@property (nonatomic) BOOL isTouchWithinCallout;
- (double)getZoomLevel;

@end

@interface MapViewController : UIViewController <MKMapViewDelegate, SMCalloutViewDelegate>

@property (nonatomic, weak) IBOutlet CustomMapView *mapView;
@property (nonatomic, weak) IBOutlet UIButton *hoursButton;
@property (nonatomic, weak) IBOutlet UIButton *unitButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UIView *feedbackView;
@property (nonatomic, weak) IBOutlet UILabel *feedbackTitleLabel;
@property (nonatomic, weak) IBOutlet UITextView *feedbackTextView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *hoursBottomLayoutGuideConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *unitBottomLayoutGuideConstraint;
@property (nonatomic) BOOL isSelectingFromTableView;

-(void)zoomToAnnotation:(MeasurementAnnotation*)annotation;
-(void)googleAnalyticsAnnotationEvent:(MeasurementAnnotation*)annotation withAction:(NSString*)action mixpanelTrack:(NSString*)track mixpanelSource:(NSString*)source;

@end
