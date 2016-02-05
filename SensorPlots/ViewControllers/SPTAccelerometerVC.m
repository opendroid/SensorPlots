//
//  SPTAccelerometerVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/2/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//


#import "SPTAccelerometerVC.h"
#import "SPTAccelerometerSetupVC.h"
#import "ATAccelerometerMotionManager.h"
#import "SPTScatterPlotGraph.h"

@import CoreMotion;

@interface SPTAccelerometerVC() <SPTAccelerometerVCProtocol, MFMailComposeViewControllerDelegate, ATAccelerometerMotionManagerDelegate, CPTPlotDataSource>

// Bar button icons accessors
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startStopSensorUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *setupUIB;

// Graph view accessors
@property (weak, nonatomic) IBOutlet CPTGraphHostingView *plotAreaGHV;

// Label to shwo different results
@property (weak, nonatomic) IBOutlet UILabel *displayBoardUIL;

// Accelerometer Manager.
@property (strong, nonatomic) ATAccelerometerMotionManager *motionManager;
@property (atomic) BOOL updatesAreInProgress; // Maintain if test was running
@property (strong, nonatomic) NSNumber *refreshRateHz; // Test refesh rate in Hz
@property (strong, nonatomic) NSMutableArray *dataArray; // Data result is here


// Handy accessor for plaotSpace
@property (strong, nonatomic) SPTScatterPlotGraph *accelerometerScatterGraph;

@end

@implementation SPTAccelerometerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.updatesAreInProgress = NO;
    self.motionManager = [[ATAccelerometerMotionManager alloc] init];
    self.motionManager.delegate = self;
    if (!self.motionManager.isAccelerometerAvailable) {
        self.composeUIB.enabled = NO;
        self.trashUIB.enabled = NO;
        self.setupUIB.enabled = NO;
        self.startStopSensorUIB.enabled = NO;
        self.displayBoardUIL.text = @"No Accelerometer available on device.";
        self.displayBoardUIL.textAlignment = NSTextAlignmentCenter;
    }
    
    self.displayBoardUIL.text = @"-";
    self.refreshRateHz = self.motionManager.refreshRateHz;
    self.dataArray = [[NSMutableArray alloc] init];
    
    // Setup graph area
    [self setupAccelerometerGraph];
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
    MFMailComposeViewController *mc = [self.motionManager emailComposerWithAccelerometerData];
    mc.mailComposeDelegate = self;
    @try {
        [self presentViewController:mc animated:YES completion:NULL];
    }
    @catch (NSException *exception) {
        self.displayBoardUIL.text = [NSString stringWithFormat:@"No email viewer."];
    }
}

- (IBAction)trashAccelerometerDataHandler:(UIBarButtonItem *)sender {
    [self.motionManager trashAccelerometerStoredData];
}

- (IBAction)startStopCapturingAccelerometerHandler:(UIBarButtonItem *)sender {
    if (! self.updatesAreInProgress) {
        sender.image = [UIImage imageNamed:@"hand25x25"];
        self.updatesAreInProgress = YES;
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
- (void) didFinishAccelerometerUpdateWithResults: (NSArray *) results {
    [self.dataArray addObjectsFromArray:results];
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.accelerometerScatterGraph.defaultPlotSpace;
    [plotSpace.graph reloadData];
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
    self.updatesAreInProgress = NO;
    
    [self.dataArray removeAllObjects];
}

#pragma mark - SPTAccelerometerVCProtocol handlers
- (void)receiveAccelerometerRefreshRateHz:(NSNumber *)value {
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

#pragma mark - Graph Area

- (void) setupAccelerometerGraph {
    // Get a graphs object
    self.accelerometerScatterGraph = [[SPTScatterPlotGraph alloc]initWithFrame:self.plotAreaGHV.bounds andTitle:@"Times G"];
    
    // Add it to the view
    self.plotAreaGHV.hostedGraph = self.accelerometerScatterGraph;
    
    // Setup Axis for Gyro
    [self.accelerometerScatterGraph adjustXAxisRange:@-20.0 length:@325.0 interval:@25.0 ticksPerInterval:2];
    [self.accelerometerScatterGraph adjustYAxisRange:@-2 length:@4 interval:@1.0 ticksPerInterval:4];
    
    
    // Add scatter plot lines for X,Y,Z and RMS.
    [self.accelerometerScatterGraph addScatterPlotX:self];
    [self.accelerometerScatterGraph addScatterPlotY:self];
    [self.accelerometerScatterGraph addScatterPlotZ:self];
    [self.accelerometerScatterGraph addScatterPlotAvg:self];
    
    // Add legend after all scatter plots have been added
    [self.accelerometerScatterGraph addLegendWithXPadding:-(self.view.bounds.size.width / 20) withYPadding:(self.view.bounds.size.height / 40)];
    self.accelerometerScatterGraph.legendAnchor = CPTRectAnchorBottomRight;
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

        default: // CPTScatterPlotFieldY values, the identifiers are hardcoded in SPTScatterPlotGraph
            if ([plot.identifier isEqual:@"X"]) {
                return [NSNumber numberWithDouble:data.acceleration.x];
            } else if ([plot.identifier isEqual:@"Y"]) {
                return [NSNumber numberWithDouble:data.acceleration.y];
            } else if ([plot.identifier isEqual:@"Z"]) {
                return [NSNumber numberWithDouble:data.acceleration.z];
            } else if ([plot.identifier isEqual:@"A"]) {
                double gValue = sqrt( (data.acceleration.x*data.acceleration.x) + (data.acceleration.y*data.acceleration.y) + (data.acceleration.z*data.acceleration.z));
                return [NSNumber numberWithDouble:gValue];
            } else {
                return @0;
            }
    }
}

@end
