//
//  vaavudViewController.m
//  VaavudCore
//
//  Created by Andreas Okholm on 5/8/13.
//  Copyright (c) 2013 Andreas Okholm. All rights reserved.
//

#import "vaavudViewController.h"
#import "VaavudCoreController.h"

@interface vaavudViewController ()

@property (nonatomic, weak) IBOutlet UILabel *mainWindSpeedLabel;
@property (nonatomic, strong) IBOutlet CPTGraphHostingView *hostView;
@property (nonatomic, strong) NSMutableArray *dataForPlot;
@property (nonatomic, strong) CPTGraph *graph;
@property (nonatomic, strong) VaavudCoreController *vaavudCoreController;
@property (nonatomic, strong) CPTXYPlotSpace *plotSpace;
@property (nonatomic) float graphTimeWidth;
@property (nonatomic) float graphMinWindspeedWidth;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic) float graphYMinValue;
@property (nonatomic) float graphYMaxValue;
@property (nonatomic, strong) NSNumber *plotCounter;

- (void) updateLabels;
- (void) updateGraphUI;
- (void) updateGraphValues;
- (void) setupCorePlotGraph;

@end

@implementation vaavudViewController {
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // TEMPORATY LOAD OF CONSTANTS
    
    self.graphTimeWidth = 15;
    self.graphMinWindspeedWidth = 4;
    self.vaavudCoreController = [[VaavudCoreController alloc] init];
    [self.vaavudCoreController start];
    
    self.dataForPlot = [NSMutableArray arrayWithCapacity:1000];

    [self setupCorePlotGraph];
    
    [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector: @selector(updateGraphUI) userInfo: nil repeats: YES];
    [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector: @selector(updateGraphValues) userInfo: nil repeats: YES];
    [NSTimer scheduledTimerWithTimeInterval: 0.2 target: self selector: @selector(updateLabels) userInfo: nil repeats: YES];

    
}

- (void) updateGraphUI
{
    
    float timeSinceStart = - [self.startTime  timeIntervalSinceNow];
    
    if (timeSinceStart > self.graphTimeWidth)
            self.plotSpace.xRange  = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(timeSinceStart - self.graphTimeWidth) length:CPTDecimalFromFloat(self.graphTimeWidth)];
        
    [self.graph reloadData];
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
        
        if (!self.startTime)
            self.startTime = [NSDate dateWithTimeIntervalSinceNow: - [x doubleValue]];
    }
            
    
    // add data points to the graph
    [self.dataForPlot addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
    
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
       
    self.plotSpace.yRange  = [CPTPlotRange plotRangeWithLocation: CPTDecimalFromFloat(graphYLowerBound) length:CPTDecimalFromFloat(graphYwidth)];
    
}


- (void) updateLabels
{
    
    NSNumber *latestWindSpeed = [self.vaavudCoreController.windSpeed lastObject];
    self.mainWindSpeedLabel.text = [NSString stringWithFormat: @"%.1f", [latestWindSpeed doubleValue]];
}


- (void) setupCorePlotGraph
{
    
    self.hostView.collapsesLayers = NO; // Setting to YES reduces GPU memory usage, but can slow drawing/scrolling
    //    self.hostView.allowPinchScaling = NO;
    
    // Create graph from theme
    self.graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    self.hostView.hostedGraph     = self.graph;
    
//    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainBlackTheme];
//    [self.graph applyTheme:theme];
    
    self.graph.fill = nil;
    self.graph.plotAreaFrame.fill = nil;
    self.graph.plotAreaFrame.borderLineStyle = nil;
    
    [self.view addSubview:self.hostView];
    
    self.graph.paddingLeft   = 0.0;
    self.graph.paddingTop    = 0.0;
    self.graph.paddingRight  = 0.0;
    self.graph.paddingBottom = 0.0;
    self.graph.plotAreaFrame.paddingLeft    = 30.0;
    self.graph.plotAreaFrame.paddingBottom  = 30.0;
    
    // Setup plot space
    self.plotSpace = (CPTXYPlotSpace *) self.graph.defaultPlotSpace;
    self.plotSpace.allowsUserInteraction = YES;
    self.plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(self.graphTimeWidth)];
    self.plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(self.graphMinWindspeedWidth)];
    
    // Axes
    CPTXYAxisSet *axisSet               = (CPTXYAxisSet *) self.graph.axisSet;
    CPTXYAxis *x                        = axisSet.xAxis;
    x.majorIntervalLength               = CPTDecimalFromString(@"10");
    x.axisConstraints                   = [CPTConstraints constraintWithLowerOffset:0.0];
    CPTMutableTextStyle *textStyleGrey  = [CPTMutableTextStyle textStyle];
    textStyleGrey.color                 = [CPTColor grayColor];
    x.labelTextStyle                    = textStyleGrey;

    
    CPTXYAxis *y                        = axisSet.yAxis;
    y.majorIntervalLength               = CPTDecimalFromString(@"2");
    CPTMutableTextStyle *textStyleWhite = [CPTMutableTextStyle textStyle];
    textStyleWhite.color                = [CPTColor whiteColor];
    y.labelTextStyle                    = textStyleWhite;
    y.axisConstraints                   = [CPTConstraints constraintWithLowerOffset:0.0];

    
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth        = 1.5;
    majorGridLineStyle.lineColor        = [CPTColor grayColor];
    y.majorGridLineStyle                = majorGridLineStyle;
    
    
    
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
    boundLinePlot.identifier    = [NSNumber numberWithInt:1];
//    boundLinePlot.identifier    = @"Blue Plot";
    boundLinePlot.dataSource    = self;
    [self.graph addPlot:boundLinePlot];
    
    

    
    
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [self.dataForPlot count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
    NSNumber *num = [[self.dataForPlot objectAtIndex:index] valueForKey:key];
    
    return num;
}

#pragma mark -
#pragma mark Axis Delegate Methods

-(BOOL)axis:(CPTAxis *)axis shouldUpdateAxisLabelsAtLocations:(NSSet *)locations
{
    
    return NO;
}





- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) newWindSpeed: (float) speed
{
    self.mainWindSpeedLabel.text = [NSString stringWithFormat: @"%.1f", speed];
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

@end
