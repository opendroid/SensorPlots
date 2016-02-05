//
//  SPTScatterPlotGraph.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "SPTScatterPlotGraph.h"

@interface SPTScatterPlotGraph()

@end

@implementation SPTScatterPlotGraph

- (instancetype) initWithFrame: (CGRect)frame andTitle: (NSString *) title {
    if (self = [super initWithFrame:frame]) {
        [self setGraphView:title];
        [self setupAxis];
        return self;
    }
    return nil;
}

- (void) setGraphView: (NSString *) title {
    self.plotAreaFrame.paddingBottom = 10;
    self.plotAreaFrame.paddingTop = 10;
    self.plotAreaFrame.paddingLeft = 10;
    self.plotAreaFrame.paddingRight = 10;
    self.borderColor = [CPTColor brownColor].cgColor;
    self.borderWidth = 3.0;
    
    // Define plot area frame.
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@-20.0 length:@220];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@-1.0 length:@2.0];
    
    // Set graph title
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor brownColor];
    titleStyle.fontSize = 30.0f;
    titleStyle.fontName = @"HelveticaNeue-Bold";
    self.titleTextStyle = titleStyle;
    self.title = title;
}

- (void) setupAxis {
    // Configure Axis lines - green color Axis and style.
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.axisSet;
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 2.0;
    axisLineStyle.lineColor = [CPTColor colorWithCGColor:[UIColor darkGrayColor].CGColor];
    axisSet.xAxis.axisLineStyle = axisLineStyle;
    axisSet.xAxis.majorTickLineStyle = axisLineStyle;
    axisSet.xAxis.minorTickLineStyle = axisLineStyle;
    axisSet.yAxis.axisLineStyle = axisLineStyle;
    axisSet.yAxis.majorTickLineStyle = axisLineStyle;
    axisSet.yAxis.minorTickLineStyle = axisLineStyle;
    
    // Setup major/minor ticks
    axisSet.xAxis.majorIntervalLength = @20.0;
    axisSet.xAxis.majorTickLength = 12;
    axisSet.xAxis.minorTicksPerInterval = 1.0;
    axisSet.xAxis.minorTickLength = 10.0;
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
    axisSet.yAxis.majorIntervalLength = @0.3;
    axisSet.yAxis.majorTickLength = 12;
    axisSet.yAxis.minorTicksPerInterval = 1;
    axisSet.yAxis.minorTickLength = 10.0;
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
    
    // Configure grid-lines major and minor
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.5f;
    majorGridLineStyle.lineColor = [CPTColor grayColor ];
    axisSet.xAxis.majorGridLineStyle = majorGridLineStyle;
    axisSet.yAxis.majorGridLineStyle = majorGridLineStyle;
    
    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.2f;
    minorGridLineStyle.lineColor = [CPTColor lightGrayColor];
    axisSet.xAxis.minorGridLineStyle = minorGridLineStyle;
    axisSet.yAxis.minorGridLineStyle = minorGridLineStyle;
    
    // Set up x/y axis labels
    NSNumberFormatter *labelFormatter = [[NSNumberFormatter alloc] init];
    labelFormatter.minimumIntegerDigits = 1;
    labelFormatter.maximumFractionDigits = 0;
    labelFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    labelFormatter.groupingSeparator = @",";
    axisSet.xAxis.labelFormatter = labelFormatter;
    axisSet.yAxis.labelFormatter = labelFormatter;
    
    // Configure font/size of the X/Y titles
    CPTMutableTextStyle *axisTextStyle = [CPTMutableTextStyle textStyle];
    axisTextStyle.color = [CPTColor brownColor];
    axisTextStyle.fontSize = 18.0f;
    axisTextStyle.fontName = @"HelveticaNeue";
    axisSet.xAxis.titleTextStyle = axisTextStyle;
    axisSet.yAxis.titleTextStyle = axisTextStyle;
    axisSet.xAxis.title = @"Sample";
    axisSet.yAxis.title = @"Value";
    axisSet.xAxis.titleOffset = -30;
    axisSet.yAxis.titleOffset = 1;
    axisSet.xAxis.titleLocation = @180;
    axisSet.yAxis.titleLocation = @01;
}

- (void) adjustXAxisRange: (NSNumber *) min length: (NSNumber *) length interval:(NSNumber *)interval ticksPerInterval:(NSUInteger) ticks {
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:min length:length];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.axisSet;
    axisSet.xAxis.majorIntervalLength = interval;
    axisSet.xAxis.minorTicksPerInterval = ticks;
    axisSet.xAxis.titleLocation = [NSNumber numberWithDouble:length.floatValue*0.85];
    
}

- (void) adjustYAxisRange: (NSNumber *) min length: (NSNumber *) length interval:(NSNumber *)interval ticksPerInterval:(NSUInteger) ticks {
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.defaultPlotSpace;
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:min length:length];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.axisSet;
    axisSet.yAxis.majorIntervalLength = interval;
    axisSet.yAxis.minorTicksPerInterval = ticks;
    
    axisSet.yAxis.titleLocation = [NSNumber numberWithDouble:length.floatValue*0.30];
}

- (void) addScatterPlotFor:(NSString *)axis withTitle:(NSString *)title lineColor:(UIColor *)lineColor delegate:(id)delegate {
    // Setup Scatter plot X.
    CPTScatterPlot *scatterPlot = [[CPTScatterPlot alloc] initWithFrame:CGRectZero];
    scatterPlot.dataSource = delegate;
    scatterPlot.delegate = delegate;
    scatterPlot.identifier = axis;
    scatterPlot.title = title;
    scatterPlot.interpolation = CPTScatterPlotInterpolationCurved;
    
    // Change Plot line - color and width of scatter plot
    CPTMutableLineStyle *scatterPlotlineStyle = [[CPTMutableLineStyle alloc] init];
    scatterPlotlineStyle.lineWidth = 4.0f;
    scatterPlotlineStyle.lineColor = [CPTColor colorWithCGColor:lineColor.CGColor];
    scatterPlot.dataLineStyle = scatterPlotlineStyle;
    
    // Fill the area under the graph.
    CPTColor *areaColor = [CPTColor clearColor];
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor clearColor]];
    areaGradient.angle = - 90.0;
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    scatterPlot.areaFill = areaGradientFill;
    scatterPlot.areaBaseValue = @0;
    
    // Add plot to the graph view
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.defaultPlotSpace;
    [self addPlot:scatterPlot toPlotSpace:plotSpace];
}

- (void) addScatterPlotX: (id) delegate {
    [self addScatterPlotFor:@"X" withTitle:@"x-value" lineColor:[UIColor orangeColor] delegate:delegate];
}

- (void) addScatterPlotY: (id) delegate {
    [self addScatterPlotFor:@"Y" withTitle:@"y-value" lineColor:[UIColor blueColor] delegate:delegate];
}

- (void) addScatterPlotZ: (id) delegate  {
    [self addScatterPlotFor:@"Z" withTitle:@"z-value" lineColor:[UIColor brownColor] delegate:delegate];

}

- (void) addScatterPlotAvg: (id) delegate {
    [self addScatterPlotFor:@"A" withTitle:@"rms-value" lineColor:[UIColor redColor] delegate:delegate];
}

- (void) addLegendWithXPadding: (CGFloat) xPadding withYPadding:(CGFloat) yPadding {

    // 1 - Create legend
    CPTLegend *theLegend = [CPTLegend legendWithGraph:self];
    // 2 - Configure legend
    theLegend.numberOfColumns = 1;
    theLegend.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
    theLegend.borderLineStyle = [CPTLineStyle lineStyle];
    theLegend.cornerRadius = 10.0;
    // 3 - Add legend to graph
    self.legend = theLegend;
    // self.legendAnchor = CPTRectAnchorBottomRight;
    CGFloat legendWPadding = xPadding;
    CGFloat legendHPadding = yPadding;
    self.legendDisplacement = CGPointMake(legendWPadding, legendHPadding);
}

@end
