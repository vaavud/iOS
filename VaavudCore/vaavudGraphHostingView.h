//
//  vaavudGraphHostingView.h
//  VaavudCore
//
//  Created by Andreas Okholm on 5/30/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "VaavudCoreController.h"
#import "CPTGraphHostingView.h"
#import "CorePlot-CocoaTouch.h"


@interface vaavudGraphHostingView : CPTGraphHostingView <CPTPlotDataSource, CPTPlotSpaceDelegate>

- (void) setupCorePlotGraph;
- (void) createNewPlot;
- (void) shiftGraphX;
- (void) addDataPoint;


@property (nonatomic, weak)     VaavudCoreController          *vaavudCoreController;


@end
