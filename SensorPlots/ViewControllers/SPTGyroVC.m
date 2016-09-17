//
//  SPTGyroVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/2/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "SPTGyroVC.h"
#import "ATSensorData.h"
#import "ATGyroMotionManager.h"
#import "SPTScatterPlotGraph.h"
#import "ATSensorData.h"
#import "SPTConstants.h"
#import "ATOUtilities.h"
#import <Google/Analytics.h>

@interface SPTGyroVC() <MFMailComposeViewControllerDelegate, ATGyroMotionManagerDelegate, CPTPlotDataSource>


@property (weak, nonatomic) IBOutlet UIBarButtonItem *startStopSensorUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *setupUIB;


@property (weak, nonatomic) IBOutlet CPTGraphHostingView *plotAreaGHV;
@property (weak, nonatomic) IBOutlet UILabel *displayBoardUIL;

// Gyro Manager.
@property (strong, nonatomic) ATGyroMotionManager *motionManager;
@property (atomic) BOOL updatesAreInProgress; // Maintain if test was running
@property (strong, nonatomic) NSNumber *refreshRateHz; // Test refesh rate in Hz
@property (atomic) BOOL  isBackgroundEnabled; // Is background mode on
@property (strong, nonatomic) NSMutableArray *dataArray; // Data result is here
@property (strong, nonatomic) id<GAITracker> gaTracker;

// Handy accessor for plaotSpace
@property (strong, nonatomic) SPTScatterPlotGraph *gyroScatterGraph;

@end

@implementation SPTGyroVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.updatesAreInProgress = NO;
    self.motionManager = [[ATGyroMotionManager alloc] init];
    self.motionManager.delegate = self;
    if (!self.motionManager.isGyroAvailable) {
        self.composeUIB.enabled = NO;
        self.trashUIB.enabled = NO;
        self.setupUIB.enabled = NO;
        self.startStopSensorUIB.enabled = NO;
        self.displayBoardUIL.text = @"Gyroscope not available.";
        self.displayBoardUIL.textAlignment = NSTextAlignmentCenter;
    } else {
        self.displayBoardUIL.text = @"-";
    }
    
    self.displayBoardUIL.text = @"-";
    self.refreshRateHz = self.motionManager.refreshRateHz;
    self.isBackgroundEnabled = [self.motionManager getGyroBackgroundMode];
    self.dataArray = [[NSMutableArray alloc] init];
    
    // Setup graph area
    [self setupGyroGraph];
    
    // Listen to app going to background.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(appEnteredBackgroundMode:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    // set up GA
    self.gaTracker = [[GAI sharedInstance] defaultTracker];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // The UA-XXXXX-Y tracker ID is loaded automatically from the
    // GoogleService-Info.plist by the `GGLContext` in the AppDelegate.
    // If you're copying this to an app just using Analytics, you'll
    // need to configure your tracking ID here.
    // [START screen_view_hit_objc]
    [self.gaTracker set:kGAIScreenName value:kATGyroVC];
    [self.gaTracker send:[[GAIDictionaryBuilder createScreenView] build]];
    // [END screen_view_hit_objc]
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Button Handlers
- (IBAction)emailGyroDataHandler:(UIBarButtonItem *)sender {
    // Check if there is data in 'GyroData' to send.
    
    NSNumber *itemsCount = self.motionManager.savedCountOfGyroDataPoints;
    if (itemsCount.integerValue < 1) {
        self.displayBoardUIL.text = [NSString stringWithFormat:@"No data to email"];
        return;
    }
    
    // Present mail view controller on screen;
    MFMailComposeViewController *mc = [self.motionManager emailComposerWithGyroData];
    mc.mailComposeDelegate = self;
    @try {
        [self presentViewController:mc animated:YES completion:NULL];
    }
    @catch (NSException *exception) {
        self.displayBoardUIL.text = [NSString stringWithFormat:@"No email viewer."];
    }
}

- (IBAction)trashGyroDataHandler:(UIBarButtonItem *)sender {
    [self.motionManager trashGyroStoredData];
}

- (IBAction)startStopCapturingGyroHandler:(UIBarButtonItem *)sender {
    if (! self.updatesAreInProgress) {
        sender.image = [UIImage imageNamed:@"hand25x25"];
        self.updatesAreInProgress = YES;
        // Disable other buttons while test in progress.
        self.composeUIB.enabled = NO;
        self.trashUIB.enabled = NO;
        self.setupUIB.enabled = NO;
        
        NSNumber *refreshRate = [ATOUtilities getGyroConfigurationFromNSU];
        [self.motionManager startGyroUpdatesWithInterval:refreshRate];
        // Track the event
        // To determine how many dragons are being rescued, send an event when the
        // player rescues a dragon.
        [self.gaTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Test" action:@"Start" label:@"Gyro" value:@1] build]];
    } else {
        sender.image = [UIImage imageNamed:@"go25x25"];
        [self.motionManager stopGyroUpdates];
    }
}

#pragma mark - ATSMotionGyroManagerDelegate handlers
- (void) didFinishGyroUpdateWithResults: (NSArray *) results maxSampleValue:(NSNumber *) max minSampleValue:(NSNumber *) min {
    // Save in a new Array
    self.dataArray = [[NSMutableArray alloc] init];
    
    // Plot the data new data set - adjust max scroll first
    if (results.count > kATMaxNumberOfSamples) {
        // Remove all but last 'kATMaxNumberOfSamplesOnAccelero' potins.
        // Dont worry the are all saved and you can email them to yourself.
        NSUInteger idxFrom = results.count - kATMaxNumberOfSamples;
        for (NSUInteger i = idxFrom; i < results.count; i++) {
            [self.dataArray addObject:results[i]];
        }
    } else { // Get all elements
        [self.dataArray addObjectsFromArray:results];
    }
    
    // Adjust Y-Axis scroll to show all values
    double minY = min.doubleValue;
    if (min.doubleValue > 0) minY = 0.0;
    NSNumber *length = [NSNumber numberWithDouble:max.doubleValue - minY];
    [self.gyroScatterGraph adjustYAxisMinValue:min length:length];

    // Reload the data inplotspace
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.gyroScatterGraph.defaultPlotSpace;
    [plotSpace.graph reloadData];
}

- (void) gyroError: (NSError *) error {
    self.displayBoardUIL.text = [NSString stringWithFormat:@"%@", error.localizedDescription];
}

- (void) gyroProgressUpdate: (UInt32) count {
    self.displayBoardUIL.text = [NSString stringWithFormat:@"%u",(unsigned int)count];
}

- (void) didTrashGyroDataCache {
    self.displayBoardUIL.text = @"Deleted stored data";
}

- (void)didStopGyroUpdate {
    // Enable other buttons while test in progress.
    self.composeUIB.enabled = YES;
    self.trashUIB.enabled = YES;
    self.setupUIB.enabled = YES;
    self.updatesAreInProgress = NO;
    
    // We may reach here if app was sent to background.
    self.startStopSensorUIB.image = [UIImage imageNamed:@"go25x25"];
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
            // Capture email notification
            [self.gaTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Email" action:@"Sent" label:@"Gyro" value:@1] build]];
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
// Pass data to child setup controller.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}

#pragma mark - Gyro Graph View Area

- (void) setupGyroGraph {
    // Get a graphs object
    self.gyroScatterGraph = [[SPTScatterPlotGraph alloc]initWithFrame:self.plotAreaGHV.bounds andTitle:@"Rad/sec RHS"];
    
    // Add it to the view
    self.plotAreaGHV.hostedGraph = self.gyroScatterGraph;

    // Setup Axis for Gyro
    // Setup x-Axis for Accelero
    NSNumber *xMin = [NSNumber numberWithDouble:kATxAxisMinimumGyro];
    NSNumber *xLength = [NSNumber numberWithDouble:kATxAxisLengthOnScreenGyro];
    NSNumber *xMajor = [NSNumber numberWithDouble:kATxAxisIntervalGyro];
    [self.gyroScatterGraph adjustXAxisRange:xMin length:xLength interval:xMajor ticksPerInterval:kATxAxisTicksInIntervalGyro];
    
    // Setup y-Axis for Accelero
    NSNumber *yMin = [NSNumber numberWithDouble:kATyAxisMinimumGyro];
    NSNumber *yLength = [NSNumber numberWithDouble:kATyAxisLengthGyro];
    NSNumber *yMajor = [NSNumber numberWithDouble:kATyAxisIntervalGyro];
    [self.gyroScatterGraph adjustYAxisRange:yMin length:yLength interval:yMajor ticksPerInterval:kATyAxisTicksInIntervalAccelero];
    
    // Add scatter plot lines for X,Y,Z and RMS.
    [self.gyroScatterGraph addScatterPlotX:self];
    [self.gyroScatterGraph addScatterPlotY:self];
    [self.gyroScatterGraph addScatterPlotZ:self];
    [self.gyroScatterGraph addScatterPlotAvg:self];
    
    // Add legend after all scatter plots have been added
    [self.gyroScatterGraph addLegendWithXPadding:-10 withYPadding:-10];
}


#pragma mark - Gyro Graph Data

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {

    return self.dataArray.count;
}

- (id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx {
    ATSensorData *data = [self.dataArray objectAtIndex:idx];
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            return [NSNumber numberWithUnsignedLong:idx];
            
        default: // CPTScatterPlotFieldY values, the identifiers are hardcoded in SPTScatterPlotGraph
            if ([plot.identifier isEqual:@"X"]) {
                return [NSNumber numberWithDouble:data.x];
            } else if ([plot.identifier isEqual:@"Y"]) {
                return [NSNumber numberWithDouble:data.y];
            } else if ([plot.identifier isEqual:@"Z"]) {
                return [NSNumber numberWithDouble:data.z];
            } else if ([plot.identifier isEqual:@"A"]) {
                double rmsValue = sqrt( (data.x * data.x) + (data.y * data.y) + (data.z * data.z));
                return [NSNumber numberWithDouble:rmsValue];
            } else {
                return @0;
            }
    }
}

#pragma mark - Handle app background event
- (void) appEnteredBackgroundMode: (UIApplication *)application {
    self.isBackgroundEnabled = [self.motionManager getGyroBackgroundMode];
    if (self.isBackgroundEnabled == NO)
        [self.motionManager stopGyroUpdates];
}

@end
