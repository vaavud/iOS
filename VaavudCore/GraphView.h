//
//  GraphHostingView.h
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 09/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#import "CPTGraphHostingView.h"
#import "CPTGraphHostingView.h"
#import "CorePlot-CocoaTouch.h"
#import "UnitUtil.h"

@interface GraphView : UIView <CPTPlotDataSource, CPTPlotSpaceDelegate>

@property (nonatomic, strong) NSDate *startTime;

- (void) changeWindSpeedUnit:(WindSpeedUnit)unit;
- (void) addPoint:(NSDate*)time currentSpeed:(NSNumber*)speed averageSpeed:(NSNumber*)average;
- (void) shiftGraphX;
@end
