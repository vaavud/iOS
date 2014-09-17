//
//  GraphHostingView.m
//  Vaavud
//
//  Created by Thomas Stilling Ambus on 09/09/2014.
//  Copyright (c) 2014 Andreas Okholm. All rights reserved.
//

#define AVERAGE_PLOT_IDENTIFIER -1
#define GRAPH_TIME_WIDTH 16.0
#define GRAPH_MIN_Y 5.0
#define GRAPH_TIME_GAP_FOR_STRAIGHT_LINE 2.0

#import "GraphView.h"
#import "UIColor+VaavudColors.h"

@interface GraphView()

@property (nonatomic) WindSpeedUnit windSpeedUnit;
@property (nonatomic) double maxWindSpeed;
@property (nonatomic, strong) CPTPlotRange *yRange;
@property (nonatomic, strong) NSNumber *averageValue;
@property (nonatomic, strong) NSNumber *latestAverageX;
@property (nonatomic, strong) NSDate *lastValueTime;

/*
 * An array of plots
 * - each plot entry consisting of an array of data
 * - each data entry consisting of a 2-element array of (x,y) pairs (doubles)
 */
@property (nonatomic, strong) NSMutableArray /*<NSMutableArray<NSArray<NSNumber>>>*/ *plots;

@property (nonatomic, strong) CPTGraphHostingView *graphHostingView;
@property (nonatomic, strong) CPTScatterPlot *currentPlot;
@property (nonatomic, strong) CPTScatterPlot *averagePlot;

@end

@implementation GraphView

- (id) initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize:WindSpeedUnitKMH];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize:WindSpeedUnitKMH];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame windSpeedUnit:(WindSpeedUnit)unit {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize:unit];
    }
    return self;
}

- (void) initialize:(WindSpeedUnit)unit {

    //NSLog(@"[GraphView] initialize");
    
    self.windSpeedUnit = unit;
    self.maxWindSpeed = 0.0;
    self.yRange = nil;
    self.averageValue = nil;
    self.latestAverageX = nil;
    self.startTime = [NSDate date];
    self.lastValueTime = nil;
    self.plots = [NSMutableArray array];

    self.graphHostingView = [[CPTGraphHostingView alloc] initWithFrame:self.bounds];
    self.graphHostingView.autoresizesSubviews = YES;
    self.graphHostingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.graphHostingView];
    
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.bounds];
    self.graphHostingView.hostedGraph = graph;

    graph.paddingLeft = 0.0;
    graph.paddingTop = 0.0;
    graph.paddingRight = 0.0;
    graph.paddingBottom = 0.0;
    graph.fill = nil;
    graph.plotAreaFrame.paddingTop = 10.0;
    graph.plotAreaFrame.paddingLeft = 30.0;
    graph.plotAreaFrame.paddingBottom = 30.0;
    graph.plotAreaFrame.fill = nil;
    graph.plotAreaFrame.borderLineStyle = nil;

    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace*) graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.delegate = self;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(GRAPH_TIME_WIDTH)];
    plotSpace.globalXRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(GRAPH_TIME_WIDTH)];
    [self updateYRange];
    //NSLog(@"[GraphView] Plot space, globalYRange=%@, yRange=%@", plotSpace.globalYRange, plotSpace.yRange);

    CPTMutableLineStyle *lineStyleGrey = [CPTMutableLineStyle lineStyle];
    lineStyleGrey.lineWidth = 1.5;
    lineStyleGrey.lineColor = [CPTColor grayColor];
    
    CPTMutableTextStyle *textStyleDarkGrey = [CPTMutableTextStyle textStyle];
    textStyleDarkGrey.color = [CPTColor darkGrayColor];
    
    CPTMutableTextStyle *textStyleGrey = [CPTMutableTextStyle textStyle];
    textStyleGrey.color = [CPTColor grayColor];
    
    NSNumberFormatter *numberFormat = [[NSNumberFormatter alloc] init];
    [numberFormat setMaximumFractionDigits: 0];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet*) graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    x.majorIntervalLength = CPTDecimalFromInt(5);
    x.minorTicksPerInterval = 0;
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    x.labelTextStyle = textStyleDarkGrey;
    x.axisLineStyle = nil;
    x.majorTickLineStyle = lineStyleGrey;
    x.minorTickLineStyle = lineStyleGrey;
    x.labelFormatter = numberFormat;
    x.majorTickLineStyle = nil;
    
    CPTXYAxis *y = axisSet.yAxis;
    y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    y.preferredNumberOfMajorTicks = 5;
    y.minorTicksPerInterval = 0;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    y.labelFormatter = numberFormat;
    y.majorGridLineStyle = nil;
    y.labelTextStyle = textStyleDarkGrey;
    y.minorTickLineStyle = nil;
    y.majorTickLineStyle = nil;
    y.axisLineStyle = nil;
    
    // create average plot...

    self.averagePlot = [[CPTScatterPlot alloc] init];
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.miterLimit = 1.0f;
    lineStyle.lineWidth = 4.0f;
    CPTColor *vaavudRed = [[CPTColor alloc] initWithComponentRed: (float) 210.0/255.0 green: (float) 37.0/255.0 blue: (float) 45.0/255.0 alpha: 1];
    lineStyle.lineColor = vaavudRed;
    
    self.averagePlot.dataLineStyle = lineStyle;
    self.averagePlot.identifier = @AVERAGE_PLOT_IDENTIFIER;
    self.averagePlot.dataSource = self;
    [graph addPlot:self.averagePlot];
    
    // create initial current plot...
    
    [self newPlot];
}

- (void) newPlot {

    NSMutableArray *plotData = [NSMutableArray arrayWithCapacity:50];
    [self.plots addObject:plotData];

    // create current plot...
    
    self.currentPlot = [[CPTScatterPlot alloc] init];
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.miterLimit = 1.0f;
    lineStyle.lineWidth = 4.0f;
    
    UIColor *vaavudColor = [UIColor vaavudColor];
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [vaavudColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    CPTColor *vaavudBlue = [[CPTColor alloc] initWithComponentRed:red green:green blue:blue alpha:alpha];
    lineStyle.lineColor = vaavudBlue;
    self.currentPlot.dataLineStyle = lineStyle;
    self.currentPlot.identifier = [NSNumber numberWithInteger:self.plots.count - 1];
    self.currentPlot.dataSource = self;
    self.currentPlot.cachePrecision = CPTPlotCachePrecisionDouble;
    
    [self.graphHostingView.hostedGraph addPlot:self.currentPlot];
}

- (void) changeWindSpeedUnit:(WindSpeedUnit)unit {
    
    if (self.windSpeedUnit != unit) {
        self.windSpeedUnit = unit;
        [self updateYRange];
        [self.graphHostingView.hostedGraph reloadData];
    }
}

- (void) addPoint:(NSDate*)time currentSpeed:(NSNumber*)speed averageSpeed:(NSNumber*)average {
    
    NSTimeInterval intervalSinceLast = 0.0;
    if (self.lastValueTime && time) {
        intervalSinceLast = [time timeIntervalSinceDate:self.lastValueTime];
        if (intervalSinceLast <= 0.0) {
            return;
        }
    }
    
    if (intervalSinceLast >= GRAPH_TIME_GAP_FOR_STRAIGHT_LINE) {
        [self newPlot];
    }
    
    if (average) {
        self.averageValue = average;
        [self.averagePlot reloadData];
    }
    
    if (time && speed) {

        NSTimeInterval interval = [time timeIntervalSinceDate:self.startTime];
        if (interval >= 0.0) {
            
            NSNumber *x = [NSNumber numberWithDouble:interval];
            self.latestAverageX = x;
            self.lastValueTime = time;
            
            if (self.plots && self.plots.count > 0) {
                NSMutableArray *data = self.plots[self.plots.count - 1];
                if (data) {
                    [data addObject:@[x, speed]];
                    [self.currentPlot insertDataAtIndex:(data.count - 1) numberOfRecords:1];
                    
                    double speedDouble = [speed doubleValue];
                    if (speedDouble > self.maxWindSpeed) {
                        self.maxWindSpeed = speedDouble;
                        [self updateYRange];
                    }
                }
                else {
                    NSLog(@"[GraphView] ERROR: No data array for current plot");
                }
            }
            else {
                NSLog(@"[GraphView] ERROR: No plots adding point");
            }
        }
        else {
            NSLog(@"[GraphView] WARNING: time interval is negative adding point, startTime=%@, time=%@", self.startTime, time);
        }
    }
}

- (void) shiftGraphX {
    
    float timeSinceStart = -[self.startTime timeIntervalSinceNow] + 1; // graph - x range should always be 1 second ahead.
    
    if (timeSinceStart > GRAPH_TIME_WIDTH) {
        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace*) self.graphHostingView.hostedGraph.defaultPlotSpace;
        plotSpace.xRange  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(timeSinceStart - GRAPH_TIME_WIDTH) length:CPTDecimalFromFloat(GRAPH_TIME_WIDTH)];
        plotSpace.globalXRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0) length:CPTDecimalFromFloat(timeSinceStart)];
    }
}

- (void) updateYRange {
    
    double maxWindSpeedLocalized = [UnitUtil displayWindSpeedFromDouble:self.maxWindSpeed unit:self.windSpeedUnit];
    double minWindSpeedLocalized = ceilf([UnitUtil displayWindSpeedFromDouble:GRAPH_MIN_Y unit:self.windSpeedUnit]);
    
    double axisMaxY = floor(maxWindSpeedLocalized) + 1.0;
    
    if (axisMaxY < minWindSpeedLocalized) {
        axisMaxY = minWindSpeedLocalized;
    }
    
    self.yRange = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(axisMaxY)];
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace*) self.graphHostingView.hostedGraph.defaultPlotSpace;
    plotSpace.globalYRange = self.yRange;
    plotSpace.yRange = self.yRange;
}

#pragma mark Plot Data Source methods

- (NSUInteger) numberOfRecordsForPlot:(CPTPlot*)plot {
    
    NSInteger identifier = [(NSNumber*) plot.identifier integerValue];
    
    if (AVERAGE_PLOT_IDENTIFIER == identifier) {
        NSUInteger records = (self.averageValue && self.latestAverageX) ? 2 : 0;
        //NSLog(@"[GraphView] Records for average plot is %u", records);
        return records;
    }
    else {
        if (self.plots && identifier < self.plots.count) {
            NSArray *data = self.plots[identifier];
            NSUInteger records = data.count;
            //NSLog(@"[GraphView] Records for plot (%u) is %u", identifier, records);
            return records;
        }
        else {
            NSLog(@"[GraphView] ERROR: No plots or identifier out of bounds (%u) getting number of records for plot", identifier);
        }
        return 0;
    }
}

- (NSNumber*) numberForPlot:(CPTPlot*)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    
    NSInteger identifier = [((NSNumber*) plot.identifier) integerValue];
    
    if (AVERAGE_PLOT_IDENTIFIER == identifier) {
        
        //NSLog(@"[GraphView] latestAverageX=%@, averageValue=%@", self.latestAverageX, self.averageValue);
        
        if (fieldEnum == CPTScatterPlotFieldX) {
            if (index == 1 && self.latestAverageX) {
                return self.latestAverageX;
            }
            return [NSNumber numberWithDouble:0.0];
        }
        else {
            if (self.averageValue) {
                return [NSNumber numberWithDouble:[UnitUtil displayWindSpeedFromDouble:[self.averageValue doubleValue] unit:self.windSpeedUnit]];
            }
            return [NSNumber numberWithDouble:0.0];
        }
    }
    else {
        if (self.plots && identifier < self.plots.count) {
            NSArray *data = self.plots[identifier];
            if (data && index < data.count) {
                NSArray *entry = data[index];
                if (entry && entry.count == 2) {
                    
                    if (fieldEnum == CPTScatterPlotFieldX) {
                        return entry[0];
                    }
                    else {
                        NSNumber *msSpeed = entry[1];
                        return [NSNumber numberWithDouble:[UnitUtil displayWindSpeedFromDouble:[msSpeed doubleValue] unit:self.windSpeedUnit]];
                    }
                }
                else {
                    NSLog(@"[GraphView] ERROR: No (x,y) data for plot (%u) at index (%u)", identifier, index);
                }
            }
            else {
                NSLog(@"[GraphView] ERROR: No data for plot (%u) or index out of bounds (%u)", identifier, index);
            }
        }
        else {
            NSLog(@"[GraphView] ERROR: No plots or identifier out of bounds (%u)", identifier);
        }
        return [NSNumber numberWithDouble:0.0];
    }
}

#pragma mark Plot Space Delegate Methods

- (CGPoint) plotSpace:(CPTPlotSpace*)space willDisplaceBy:(CGPoint)displacement {
    // only displace in X
    return CGPointMake(displacement.x,0);
}

- (CPTPlotRange*) plotSpace:(CPTPlotSpace*)space willChangePlotRangeTo:(CPTPlotRange*)newRange forCoordinate:(CPTCoordinate)coordinate {
    // do not zoom in Y
    if (coordinate == CPTCoordinateY && self.yRange) {
        newRange = self.yRange;
    }
    return newRange;
}

@end
