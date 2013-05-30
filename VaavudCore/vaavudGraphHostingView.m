//
//  vaavudGraphHostingView.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/30/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "vaavudGraphHostingView.h"


@interface vaavudGraphHostingView ()

- (void) createNewPlot;


@property (nonatomic, strong)   NSMutableArray *dataForPlot;
@property (nonatomic, strong)   CPTGraph    *graph;
@property (nonatomic, strong)   CPTXYPlotSpace *plotSpace;
@property (nonatomic)           float       graphTimeWidth;
@property (nonatomic)           float       graphMinWindspeedWidth;
@property (nonatomic, strong)   NSDate      *startTime;
@property (nonatomic)           float       graphYMinValue;
@property (nonatomic)           float       graphYMaxValue;
@property (nonatomic)           NSUInteger  plotCounter;
@property (nonatomic)           double      startTimeDifference;


@property (nonatomic) BOOL      wasValid;


enum plotName : NSUInteger {
    averagePlot = 0
};

@end

@implementation vaavudGraphHostingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void) updateGraphUI
{
    
    if ([[self.vaavudCoreController.isValid lastObject] boolValue]) {
        float timeSinceStart = - [self.startTime  timeIntervalSinceNow] - self.startTimeDifference + 1;
        
        if (timeSinceStart > self.graphTimeWidth) {
            self.plotSpace.xRange  = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(timeSinceStart - self.graphTimeWidth) length:CPTDecimalFromFloat(self.graphTimeWidth)];
            self.plotSpace.globalXRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(0) length: CPTDecimalFromFloat(timeSinceStart)];
        }
        
        [self.graph reloadData];
        
    }
}


- (void) updateGraphValues
{
    
    
    float graphYLowerBound;
    float graphYwidth;
    
    NSNumber *x = [self.vaavudCoreController.time lastObject];
    NSNumber *y = [self.vaavudCoreController.windSpeed lastObject];
    
    
    // on start set Graph minimum values and startTime
    
    if (!self.graphYMinValue) {
        self.graphYMinValue = [y floatValue];
        if (!self.graphYMaxValue)
            self.graphYMaxValue = [y floatValue];
    }
    
    
    BOOL isValid = [[self.vaavudCoreController.isValid lastObject] boolValue];
    
    if (isValid && !self.wasValid)
        [self createNewPlot];
    
    self.wasValid = isValid;
    
    if (isValid) {
        
        if (!self.startTime) {
            self.startTime = [NSDate dateWithTimeIntervalSinceNow: - [x doubleValue]];
            self.startTimeDifference = [x doubleValue];
        }
        
        NSNumber *xtime = [NSNumber numberWithDouble:([x doubleValue] - self.startTimeDifference) ];
        
        
        [[self.dataForPlot objectAtIndex: self.plotCounter] addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:xtime, @"x", y, @"y", nil]];
        
        
        // update min and max values
        if ([y floatValue] > self.graphYMaxValue)
            self.graphYMaxValue = [y floatValue];
        
        if ([y floatValue] < self.graphYMinValue)
            self.graphYMinValue = [y floatValue];
        
        
        // determine y window range
        if (self.graphYMinValue < 2)
            graphYLowerBound = 0;
        else
            graphYLowerBound = floor(self.graphYMinValue);
        
        graphYwidth = floor(self.graphYMaxValue) +1 - graphYLowerBound;
        
        if (graphYwidth < self.graphMinWindspeedWidth)
            graphYwidth = self.graphMinWindspeedWidth;
        
        CPTPlotRange *plotRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(graphYLowerBound) length:CPTDecimalFromFloat(graphYwidth)];
        
        self.plotSpace.yRange  = plotRange;
        self.plotSpace.globalYRange = plotRange;
        
        
        // add average
        
        NSMutableArray *averageDataArray =  [NSMutableArray arrayWithCapacity:2];
        [averageDataArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat:0.f], @"x", [self.vaavudCoreController getAverage], @"y", nil]];
        [averageDataArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: xtime, @"x", [self.vaavudCoreController getAverage], @"y", nil]];
        
        
        [self.dataForPlot replaceObjectAtIndex: averagePlot withObject: averageDataArray];
    }
    
}



- (void) createNewPlot
{
    self.plotCounter++;
    
    
    // Create a blue plot area
    CPTScatterPlot *boundLinePlot       = [[CPTScatterPlot alloc] init];
    CPTMutableLineStyle *lineStyle      = [CPTMutableLineStyle lineStyle];
    lineStyle.miterLimit                = 1.0f;
    lineStyle.lineWidth                 = 3.0f;
    //    boundLinePlot.interpolation         = CPTScatterPlotInterpolationCurved;
    CPTColor *vaavudBlue = [[CPTColor alloc] initWithComponentRed: 0 green: (float) 174/255 blue: (float) 239/255 alpha: 1 ];
    
    
    //    lineStyle.lineColor         = [CPTColor blueColor];
    lineStyle.lineColor         = vaavudBlue;
    boundLinePlot.dataLineStyle = lineStyle;
    boundLinePlot.identifier    = [NSNumber numberWithInt: self.plotCounter];
    //    boundLinePlot.identifier    = @"Blue Plot";
    boundLinePlot.dataSource    = self;
    [self.dataForPlot insertObject: [NSMutableArray arrayWithCapacity:1] atIndex: self.plotCounter];
    [self.graph addPlot:boundLinePlot];
}



- (void) setupCorePlotGraph
{
    
    self.plotCounter = 0;
    self.startTime = nil;
    self.graphYMaxValue = 0;
    self.graphYMinValue = 0;
    self.dataForPlot = [NSMutableArray arrayWithCapacity:1];
    
    
    // TEMPORATY LOAD OF CONSTANTS
    self.graphTimeWidth = 16;
    self.graphMinWindspeedWidth = 4;
    
    self.collapsesLayers = NO; // Setting to YES reduces GPU memory usage, but can slow drawing/scrolling
    
    // Create graph from theme
    self.graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    self.hostedGraph     = self.graph;
    
    self.graph.fill = nil;
    self.graph.plotAreaFrame.fill = nil;
    self.graph.plotAreaFrame.borderLineStyle = nil;
    
    //    [self.view addSubview:self.hostView];
    
    self.graph.paddingLeft   = 0.0;
    self.graph.paddingTop    = 0.0;
    self.graph.paddingRight  = 0.0;
    self.graph.paddingBottom = 0.0;
    self.graph.plotAreaFrame.paddingTop     = 10.0;
    self.graph.plotAreaFrame.paddingLeft    = 30.0;
    self.graph.plotAreaFrame.paddingBottom  = 30.0;
    
    // Setup plot space
    self.plotSpace = (CPTXYPlotSpace *) self.graph.defaultPlotSpace;
    self.plotSpace.allowsUserInteraction = YES;
    self.plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(self.graphTimeWidth)];
    self.plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(self.graphMinWindspeedWidth)];
    self.plotSpace.GlobalXRange          = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(self.graphTimeWidth)];
    self.plotSpace.GlobalYRange          = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(self.graphMinWindspeedWidth)];
    self.plotSpace.delegate = self;
    
    // Axes
    
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth        = 1.5;
    majorGridLineStyle.lineColor        = [CPTColor lightGrayColor];
    
    CPTMutableLineStyle *GreyLineStyle = [CPTMutableLineStyle lineStyle];
    GreyLineStyle.lineWidth        = 1.5;
    GreyLineStyle.lineColor        = [CPTColor grayColor];
    
    
    CPTMutableTextStyle *textStyleDarkGrey = [CPTMutableTextStyle textStyle];
    textStyleDarkGrey.color                = [CPTColor darkGrayColor];
    
    CPTMutableTextStyle *textStyleGrey  = [CPTMutableTextStyle textStyle];
    textStyleGrey.color                 = [CPTColor grayColor];
    
    NSNumberFormatter *numberFormat     = [[NSNumberFormatter alloc] init];
    [numberFormat setMaximumFractionDigits: 0];
    
    CPTXYAxisSet *axisSet               = (CPTXYAxisSet *) self.graph.axisSet;
    CPTXYAxis *x                        = axisSet.xAxis;
    x.majorIntervalLength               = CPTDecimalFromInt(5);
    x.minorTicksPerInterval             = 0;
    x.axisConstraints                   = [CPTConstraints constraintWithLowerOffset:0.0];
    x.labelTextStyle                    = textStyleGrey;
    x.axisLineStyle                     = GreyLineStyle;
    x.majorTickLineStyle                = GreyLineStyle;
    x.minorTickLineStyle                = GreyLineStyle;
    x.labelFormatter                    = numberFormat;
    x.majorTickLineStyle                = nil;
    
    
    CPTXYAxis *y                        = axisSet.yAxis;
    y.majorIntervalLength               = CPTDecimalFromInt(2);
    y.minorTicksPerInterval             = 0;
    y.axisConstraints                   = [CPTConstraints constraintWithLowerOffset:0.0];
    y.labelFormatter                    = numberFormat;
    y.majorGridLineStyle                = majorGridLineStyle;
    y.labelTextStyle                    = textStyleDarkGrey;
    y.minorTickLineStyle                = nil;
    y.majorTickLineStyle                = nil;
    y.axisLineStyle                     = nil;
    
    
    
    
    
    
    
    // create Red Average  // Create a blue plot area
    CPTScatterPlot *averageLinePlot       = [[CPTScatterPlot alloc] init];
    CPTMutableLineStyle *lineStyle      = [CPTMutableLineStyle lineStyle];
    lineStyle.miterLimit                = 1.0f;
    lineStyle.lineWidth                 = 3.0f;
    CPTColor *vaavudRed = [[CPTColor alloc] initWithComponentRed: (float) 210/255 green: (float) 37/255 blue: (float) 45/255 alpha: 1 ];
    
    
    //   lineStyle.lineColor         = [CPTColor whiteColor];
    lineStyle.lineColor         = vaavudRed;
    averageLinePlot.dataLineStyle = lineStyle;
    averageLinePlot.identifier    = [NSNumber numberWithInt: averagePlot];
    averageLinePlot.dataSource    = self;
    [self.dataForPlot insertObject: [NSMutableArray arrayWithCapacity:1] atIndex: averagePlot];
    [self.graph addPlot:averageLinePlot];
    
    
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    NSUInteger mainIndex = [(NSNumber *) plot.identifier integerValue];
    NSUInteger count = [[self.dataForPlot objectAtIndex: mainIndex] count];
    return count;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    
    NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
    NSUInteger mainIndex = [(NSNumber *) plot.identifier integerValue];
    NSNumber *num = [[[self.dataForPlot objectAtIndex:mainIndex] objectAtIndex: index] valueForKey:key];
    
    return num;
    
    
}



// only displace in X
-(CGPoint)plotSpace:(CPTPlotSpace *)space willDisplaceBy:(CGPoint)displacement{
    return CGPointMake(displacement.x,0);}

// do not zoom in Y
-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate{
    if (coordinate == CPTCoordinateY) {
        newRange = ((CPTXYPlotSpace*)space).yRange;
    }
    return newRange;}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
