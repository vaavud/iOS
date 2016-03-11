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
#import "MeasurementAnnotation.h"

@interface CustomMapView : MKMapView

@property (nonatomic) SMCalloutView *calloutView;
@property (nonatomic) BOOL isTouchWithinCallout;
- (double)getZoomLevel;

@end

@interface MapViewController : UIViewController <MKMapViewDelegate, SMCalloutViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet CustomMapView *mapView;
@property (nonatomic) BOOL isSelectingFromTableView;

-(void)zoomToAnnotation:(MeasurementAnnotation *)annotation;

@end
