//
//  SPTScatterPlotGraph.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "CorePlot-CocoaTouch.h"

@interface SPTScatterPlotGraph : CPTXYGraph

// Initilizer
- (instancetype) initWithFrame: (CGRect)frame andTitle: (NSString *) title;

// Call after initilization to change the axis
- (void) adjustXAxisRange: (NSNumber *) min length: (NSNumber *) length interval:(NSNumber *)interval ticksPerInterval:(NSUInteger) ticks;
- (void) adjustYAxisRange: (NSNumber *) min length: (NSNumber *) length interval:(NSNumber *)interval ticksPerInterval:(NSUInteger) ticks;


// Convinient setup for X,Y,Z, RMS scatter plot
- (void) addScatterPlotX: (id) delegate;
- (void) addScatterPlotY: (id) delegate;
- (void) addScatterPlotZ: (id) delegate;
- (void) addScatterPlotAvg: (id) delegate;

// Always setup Legend after the scatter plots have been added.
- (void) addLegendWithXPadding: (CGFloat) xPadding withYPadding:(CGFloat) yPadding;

@end
