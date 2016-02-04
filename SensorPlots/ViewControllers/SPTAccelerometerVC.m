//
//  SPTAccelerometerVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/2/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "AppDelegate.h"
#import "SPTAccelerometerVC.h"
#import "CorePlot-CocoaTouch.h"
#import "SPTAccelerometerSetupVC.h"
#import "AccelerometerData.h"
#import "NSDate+BootTime.h"
#import "ATSMotionAccelerometerManager.h"

@import CoreMotion;

@interface SPTAccelerometerVC() <SPTAccelerometerVCProtocol, MFMailComposeViewControllerDelegate, ATSMotionAccelerometerManagerDelegate, CPTPlotDataSource>
@property (weak, nonatomic) IBOutlet CPTGraphHostingView *plotAreaGHV;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *goAccelerometerUIB;
@property (weak, nonatomic) IBOutlet UILabel *displayBoardUIL;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *setupUIB;

// Accelerometer Manager.
@property (strong, nonatomic) ATSMotionAccelerometerManager *motionManager;
@property (atomic) BOOL accelerometerUpdateInProgress; // Maintain if test was running
@property (strong, nonatomic) NSNumber *refreshRateHz; // Test refesh rate in Hz
@property (strong, nonatomic) NSMutableArray *dataArray; // Data result is here


// Graph realted
@property (strong, nonatomic) CPTXYPlotSpace *plotSpace;

@end

@implementation SPTAccelerometerVC


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.accelerometerUpdateInProgress = NO;
    self.motionManager = [[ATSMotionAccelerometerManager alloc] init];
    self.motionManager.delegate = self;
    if (!self.motionManager.isAccelerometerAvailable) {
        self.composeUIB.enabled = NO;
        self.trashUIB.enabled = NO;
        self.setupUIB.enabled = NO;
        self.goAccelerometerUIB.enabled = NO;
        self.displayBoardUIL.text = @"No Accelerometer available on device.";
        self.displayBoardUIL.textAlignment = NSTextAlignmentCenter;
    }
    
    self.displayBoardUIL.text = @"-";
    self.refreshRateHz = self.motionManager.refreshRateHz;
    self.dataArray = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Button Handlers
- (IBAction)emailAccelerometerDataHandler:(UIBarButtonItem *)sender {
    // Check if there is data in 'AccelerometerData' to send.

    NSNumber *itemsCount = self.motionManager.savedCountOfAcclerometerDataPoints;
    if (itemsCount.integerValue < 1) {
        self.displayBoardUIL.text = [NSString stringWithFormat:@"No data to email"];
        return;
    }
        
    // Present mail view controller on screen;
    MFMailComposeViewController *mc = [self.motionManager emailComposerWithTestData];
    mc.mailComposeDelegate = self;
    [self presentViewController:mc animated:YES completion:NULL];
}

- (IBAction)trashAccelerometerDataHandler:(UIBarButtonItem *)sender {
    [self.motionManager trashAccelerometerStoredData];
}

- (IBAction)startStopCapturingAccelerometerHandler:(UIBarButtonItem *)sender {
    if (! self.accelerometerUpdateInProgress) {
        sender.image = [UIImage imageNamed:@"hand25x25"];
        self.accelerometerUpdateInProgress = YES;
        // Disable other buttons while test in progress.
        self.composeUIB.enabled = NO;
        self.trashUIB.enabled = NO;
        self.setupUIB.enabled = NO;
        [self.motionManager startAccelerometerUpdates];
        
    } else {
        sender.image = [UIImage imageNamed:@"go25x25"];
        [self.motionManager stopAccelerometerUpdates];
    }
}

#pragma mark - ATSMotionAccelerometerManagerDelegate handlers
- (void) didFinishAccelerometerTestWithResults: (NSArray *) results {
    [self.dataArray addObjectsFromArray:results];
    [self graphAccelerometerData];
    [self.plotSpace.graph reloadData];
}

- (void) accelerometerError: (NSError *) error {
    self.displayBoardUIL.text = [NSString stringWithFormat:@"%@", error.localizedDescription];
}

- (void) accelerometerProgressUpdate: (UInt32) count {
    self.displayBoardUIL.text = [NSString stringWithFormat:@"%u",count];
}

- (void) didTrashAccelerometerDataCache {
    self.displayBoardUIL.text = @"Deleted stored data";
}

- (void)didStopAccelerometerUpdate {
    // Enable other buttons while test in progress.
    self.composeUIB.enabled = YES;
    self.trashUIB.enabled = YES;
    self.setupUIB.enabled = YES;
    self.accelerometerUpdateInProgress = NO;
    
    [self.dataArray removeAllObjects];
}

#pragma mark - SPTAccelerometerVCProtocol handlers
- (void)receiveAcceleratorRefreshRateHz:(NSNumber *)value {
    self.refreshRateHz = [self.motionManager accelerometerUpdateInterval:value];
}

#pragma mark - Mail Composers
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    // Completed the viewer.
    switch (result)
    {
        case MFMailComposeResultCancelled:
            self.displayBoardUIL.text = @"Email is not sent.";
            break;
        case MFMailComposeResultSaved:
            self.displayBoardUIL.text = @"Data email saved in draft.";
            break;
        case MFMailComposeResultSent:
            self.displayBoardUIL.text = @"Data sent in email.";
            break;
        case MFMailComposeResultFailed:
            self.displayBoardUIL.text = [NSString stringWithFormat:@"Mail sent failure: %@", error.localizedDescription];
            break;
        default:
            break;
    }
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Segue Handlers
// Pass data to child controller.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    SPTAccelerometerSetupVC *setupVC = segue.destinationViewController;
    setupVC.title = @"Setup Accelerometer";
    setupVC.refreshRateHz = [NSNumber numberWithFloat:self.refreshRateHz.doubleValue];
    setupVC.countOfTestDataValues = [self.motionManager savedCountOfAcclerometerDataPoints];
    setupVC.delegate = self;
}

#pragma mark - Utility methods
// Show 'showAppAlertWithMessage' a utility to show a alert message
- (void) showAppAlertWithMessage: (NSString *) message
               andViewController: (SPTAccelerometerVC *) vc {
    UIAlertController *okVC = [UIAlertController alertControllerWithTitle:@"Sensor Plots" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [okVC addAction:okAction];
    [vc presentViewController:okVC animated:YES completion:nil];
}

#pragma mark - Graph Area

- (void) graphAccelerometerData {
    [self initGraph];
    [self setupAxis];
    [self setupScatterPlotX];
    [self setupScatterPlotY];
    [self setupScatterPlotZ];
    [self setupScatterPlotG];
    [self setupLegend];
}

- (void) initGraph {
    // Setup the graph view with a plot space and X/Y Range
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.plotAreaGHV.bounds];
    self.plotAreaGHV.hostedGraph = graph;
    graph.plotAreaFrame.paddingBottom = 10;
    graph.plotAreaFrame.paddingTop = 10;
    graph.plotAreaFrame.paddingLeft = 10;
    graph.plotAreaFrame.paddingRight = 10;
    graph.borderColor = [CPTColor brownColor].cgColor;
    graph.borderWidth = 3.0;
    
    // Define plot area frame.
    self.plotSpace = (CPTXYPlotSpace *) self.plotAreaGHV.hostedGraph.defaultPlotSpace;
    self.plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@-20.0 length:@220];
    self.plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@-2.0 length:@4];
    
    // Set graph title
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor brownColor];
    titleStyle.fontSize = 30.0f;
    titleStyle.fontName = @"HelveticaNeue-Bold";
    graph.titleTextStyle = titleStyle;
    graph.title = @"xyz-g Data";
}

- (void) setupAxis {
    // Configure Axis lines - green color Axis and style.
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.plotAreaGHV.hostedGraph.axisSet;
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
    axisSet.yAxis.majorIntervalLength = @1.0;
    axisSet.yAxis.majorTickLength = 12;
    axisSet.yAxis.minorTicksPerInterval = 4;
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
    axisSet.yAxis.titleOffset = 2;
    axisSet.xAxis.titleLocation = @180;
    axisSet.yAxis.titleLocation = @1;
}

- (void) setupScatterPlotX {
    // Setup Scatter plot X.
    CPTScatterPlot *scatterPlot = [[CPTScatterPlot alloc] initWithFrame:CGRectZero];
    scatterPlot.dataSource = self;
    scatterPlot.delegate = self;
    scatterPlot.identifier = @"X";
    scatterPlot.title = @"x-value:";
    scatterPlot.interpolation = CPTScatterPlotInterpolationCurved;
    
    // Change Plot line - color and width of scatter plot
    CPTMutableLineStyle *scatterPlotlineStyle = [[CPTMutableLineStyle alloc] init];
    scatterPlotlineStyle.lineWidth = 4.0f;
    scatterPlotlineStyle.lineColor = [CPTColor colorWithCGColor:[UIColor orangeColor].CGColor];
    scatterPlot.dataLineStyle = scatterPlotlineStyle;
    
    // Fill the area under the graph.
    CPTColor *areaColor = [CPTColor clearColor];
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor clearColor]];
    areaGradient.angle = - 90.0;
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    scatterPlot.areaFill = areaGradientFill;
    scatterPlot.areaBaseValue = @0;
    
    // Add plot to the graph view
    [self.plotAreaGHV.hostedGraph addPlot:scatterPlot toPlotSpace:self.plotSpace];
}

- (void) setupScatterPlotY {
    // Setup Scatter plot Y.
    CPTScatterPlot *scatterPlot = [[CPTScatterPlot alloc] initWithFrame:CGRectZero];
    scatterPlot.dataSource = self;
    scatterPlot.delegate = self;
    scatterPlot.identifier = @"Y";
    scatterPlot.title = @"y-value:";
    scatterPlot.interpolation = CPTScatterPlotInterpolationCurved;
    
    // Change Plot line - color and width of scatter plot
    CPTMutableLineStyle *scatterPlotlineStyle = [[CPTMutableLineStyle alloc] init];
    scatterPlotlineStyle.lineWidth = 4.0f;
    scatterPlotlineStyle.lineColor = [CPTColor colorWithCGColor:[UIColor blueColor].CGColor];
    scatterPlot.dataLineStyle = scatterPlotlineStyle;
    
    // Fill the area under the graph.
    CPTColor *areaColor = [CPTColor clearColor];
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor clearColor]];
    areaGradient.angle = - 90.0;
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    scatterPlot.areaFill = areaGradientFill;
    scatterPlot.areaBaseValue = @0;
    
    // Add plot to the graph view
    [self.plotAreaGHV.hostedGraph addPlot:scatterPlot toPlotSpace:self.plotSpace];
}

- (void) setupScatterPlotZ {
    // Setup Scatter plot Z.
    CPTScatterPlot *scatterPlot = [[CPTScatterPlot alloc] initWithFrame:CGRectZero];
    scatterPlot.dataSource = self;
    scatterPlot.delegate = self;
    scatterPlot.identifier = @"Z";
    scatterPlot.title = @"z-value:";
    scatterPlot.interpolation = CPTScatterPlotInterpolationCurved;
    
    // Change Plot line - color and width of scatter plot
    CPTMutableLineStyle *scatterPlotlineStyle = [[CPTMutableLineStyle alloc] init];
    scatterPlotlineStyle.lineWidth = 4.0f;
    scatterPlotlineStyle.lineColor = [CPTColor colorWithCGColor:[UIColor brownColor].CGColor];
    scatterPlot.dataLineStyle = scatterPlotlineStyle;
    
    // Fill the area under the graph.
    CPTColor *areaColor = [CPTColor clearColor];
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor clearColor]];
    areaGradient.angle = - 90.0;
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    scatterPlot.areaFill = areaGradientFill;
    scatterPlot.areaBaseValue = @0;
    
    // Add plot to the graph view
    [self.plotAreaGHV.hostedGraph addPlot:scatterPlot toPlotSpace:self.plotSpace];
}


- (void) setupScatterPlotG {
    // Setup Scatter plot G.
    CPTScatterPlot *scatterPlot = [[CPTScatterPlot alloc] initWithFrame:CGRectZero];
    scatterPlot.dataSource = self;
    scatterPlot.delegate = self;
    scatterPlot.identifier = @"G";
    scatterPlot.title = @"g-value:";
    scatterPlot.interpolation = CPTScatterPlotInterpolationCurved;
    
    // Change Plot line - color and width of scatter plot
    CPTMutableLineStyle *scatterPlotlineStyle = [[CPTMutableLineStyle alloc] init];
    scatterPlotlineStyle.lineWidth = 4.0f;
    scatterPlotlineStyle.lineColor = [CPTColor colorWithCGColor:[UIColor redColor].CGColor];
    scatterPlot.dataLineStyle = scatterPlotlineStyle;
    
    // Fill the area under the graph.
    CPTColor *areaColor = [CPTColor clearColor];
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor clearColor]];
    areaGradient.angle = - 90.0;
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    scatterPlot.areaFill = areaGradientFill;
    scatterPlot.areaBaseValue = @0;
    
    // Add plot to the graph view
    [self.plotAreaGHV.hostedGraph addPlot:scatterPlot toPlotSpace:self.plotSpace];
}


- (void) setupLegend {
    // 1 - Create legend
    CPTLegend *theLegend = [CPTLegend legendWithGraph:self.plotAreaGHV.hostedGraph];
    // 2 - Configure legend
    theLegend.numberOfColumns = 1;
    theLegend.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
    theLegend.borderLineStyle = [CPTLineStyle lineStyle];
    theLegend.cornerRadius = 10.0;
    // 3 - Add legend to graph
    self.plotAreaGHV.hostedGraph.legend = theLegend;
    self.plotAreaGHV.hostedGraph.legendAnchor = CPTRectAnchorBottomRight;
    CGFloat legendWPadding = -(self.view.bounds.size.width / 20);
    CGFloat legendHPadding = (self.view.bounds.size.height / 40);
    self.plotAreaGHV.hostedGraph.legendDisplacement = CGPointMake(legendWPadding, legendHPadding);
}
#pragma mark - Graph Data

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return self.dataArray.count;
}

- (id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx {
    CMAccelerometerData *data = [self.dataArray objectAtIndex:idx];
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            return [NSNumber numberWithUnsignedLong:idx];

        default: // CPTScatterPlotFieldY values
            if ([plot.identifier isEqual:@"X"]) {
                return [NSNumber numberWithDouble:data.acceleration.x];
            } else if ([plot.identifier isEqual:@"Y"]) {
                return [NSNumber numberWithDouble:data.acceleration.y];
            } else if ([plot.identifier isEqual:@"Z"]) {
                return [NSNumber numberWithDouble:data.acceleration.z];
            } else if ([plot.identifier isEqual:@"G"]) {
                double gValue = sqrt( (data.acceleration.x*data.acceleration.x) + (data.acceleration.y*data.acceleration.y) + (data.acceleration.z*data.acceleration.z));
                return [NSNumber numberWithDouble:gValue];
            } else {
                return @0;
            }
    }
}

@end
