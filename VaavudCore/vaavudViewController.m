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

@property (nonatomic, weak) IBOutlet UILabel *actualLabel;
@property (nonatomic, weak) IBOutlet UILabel *averageLabel;
@property (nonatomic, weak) IBOutlet UILabel *maxLabel;
@property (nonatomic, weak) IBOutlet UILabel *informationTextLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *statusBar;


@property (nonatomic, strong) IBOutlet CPTGraphHostingView *hostView;
@property (nonatomic, strong) IBOutlet UIButton *startStopButton;
@property (nonatomic, strong) NSMutableArray *dataForPlot;
@property (nonatomic, strong) CPTGraph *graph;
@property (nonatomic, strong) VaavudCoreController *vaavudCoreController;
@property (nonatomic, strong) CPTXYPlotSpace *plotSpace;
@property (nonatomic) float     graphTimeWidth;
@property (nonatomic) float     graphMinWindspeedWidth;
@property (nonatomic, strong)   NSDate *startTime;
@property (nonatomic) float     graphYMinValue;
@property (nonatomic) float     graphYMaxValue;
@property (nonatomic) NSUInteger plotCounter;
@property (nonatomic) BOOL      wasValid;
@property (nonatomic) double    startTimeDifference;

@property (nonatomic, strong) NSTimer *TimerLabel;
@property (nonatomic, strong) NSTimer *TimerGraphUI;
@property (nonatomic, strong) NSTimer *TimerGraphValues;

- (void) updateLabels;
- (void) updateGraphUI;
- (void) updateGraphValues;
- (void) setupCorePlotGraph;
- (void) createNewPlot;
- (void) start;
- (void) stop;

- (IBAction) buttonPushed: (id)sender;

@end

@implementation vaavudViewController {
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // TEMPORATY LOAD OF CONSTANTS
    [self setupCorePlotGraph];

    self.graphTimeWidth = 16;
    self.graphMinWindspeedWidth = 4;
    [self setupCorePlotGraph];

    
//    self.startStopButton = [[UIButton alloc] init];
//    [self.startStopButton setTitle:(NSString *) forState:(UIControlState)]
    
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.vaavudCoreController stop];
}

- (void) start {
    
    self.vaavudCoreController = [[VaavudCoreController alloc] init];
    
    self.plotCounter = -1;
    
    self.dataForPlot = [NSMutableArray arrayWithCapacity:20];
    
    [self setupCorePlotGraph];
    
    self.TimerGraphUI       = [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector: @selector(updateGraphUI) userInfo: nil repeats: YES];
    self.TimerGraphValues   = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector: @selector(updateGraphValues) userInfo: nil repeats: YES];
    self.TimerLabel         = [NSTimer scheduledTimerWithTimeInterval: 0.2 target: self selector: @selector(updateLabels) userInfo: nil repeats: YES];
    [self.vaavudCoreController start];
    
    [self.statusBar setProgress:0];
}

- (void) stop {
    [self.TimerGraphUI invalidate];
    [self.TimerGraphValues invalidate];
    [self.TimerLabel invalidate];
    [self.vaavudCoreController stop];
    
    self.startTime = nil;
    self.graphYMaxValue = 0;
    self.graphYMinValue = 0;
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
            
    
    // add data points to the graph
//    [self.dataForPlot addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
    
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
        
    }
            
}


- (void) updateLabels
{
    BOOL isValid = [[self.vaavudCoreController.isValid lastObject] boolValue];

    if (isValid) {
        NSNumber *latestWindSpeed = [self.vaavudCoreController.windSpeed lastObject];
        self.actualLabel.text = [NSString stringWithFormat: @"%.1f", [latestWindSpeed doubleValue]];
        self.averageLabel.text = [NSString stringWithFormat: @"%.1f", [[self.vaavudCoreController getAverage] floatValue]];
        self.maxLabel.text = [NSString stringWithFormat: @"%.1f", [[self.vaavudCoreController getMax] floatValue]];
        
        self.informationTextLabel.text = @"";
        
        [self.statusBar setProgress: [[self.vaavudCoreController getProgress] floatValue]];
        
    } else {
        self.actualLabel.text = @"-";
//        self.averageLabel.text = @"-";
//        self.maxLabel.text = @"-";
        
        if (self.vaavudCoreController.dynamicsIsValid)
            self.informationTextLabel.text = @"No signal";
        else
            self.informationTextLabel.text = @"Keep vertical & steady";

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
    majorGridLineStyle.lineColor        = [CPTColor grayColor];
    
    CPTXYAxisSet *axisSet               = (CPTXYAxisSet *) self.graph.axisSet;
    CPTXYAxis *x                        = axisSet.xAxis;
    x.majorIntervalLength               = CPTDecimalFromInt(5);
    x.axisConstraints                   = [CPTConstraints constraintWithLowerOffset:0.0];
    CPTMutableTextStyle *textStyleGrey  = [CPTMutableTextStyle textStyle];
    textStyleGrey.color                 = [CPTColor grayColor];
    x.labelTextStyle                    = textStyleGrey;
    x.axisLineStyle                     = majorGridLineStyle;
    
    NSNumberFormatter *numberFormat     = [[NSNumberFormatter alloc] init];
    [numberFormat setMaximumFractionDigits: 0];
    x.labelFormatter                    = numberFormat;

    
    CPTXYAxis *y                        = axisSet.yAxis;
    y.majorIntervalLength               = CPTDecimalFromInt(2);
    CPTMutableTextStyle *textStyleWhite = [CPTMutableTextStyle textStyle];
    textStyleWhite.color                = [CPTColor whiteColor];
    y.labelTextStyle                    = textStyleWhite;
    y.axisConstraints                   = [CPTConstraints constraintWithLowerOffset:0.0];
    y.labelFormatter                    = numberFormat;
    
    y.majorGridLineStyle                = majorGridLineStyle;
    
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




- (IBAction) buttonPushed: (UIButton*) sender
{
    
    NSString *buttonText = [NSString stringWithString: sender.currentTitle];
    
    if ([buttonText caseInsensitiveCompare: @"start"] == NSOrderedSame){
        [self.startStopButton setTitle: @"stop" forState:UIControlStateNormal];
        [self start];
    }
    
    if ([buttonText caseInsensitiveCompare: @"stop"] == NSOrderedSame){
        [self.startStopButton setTitle: @"start" forState:UIControlStateNormal];
        [self stop];
    }
        

}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void) newWindSpeed: (float) speed
//{
//    self.mainWindSpeedLabel.text = [NSString stringWithFormat: @"%.1f", speed];
//}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

@end
