//
//  SPTAccelerometerVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/2/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//


#import "SPTAccelerometerVC.h"
#import "SPTAccelerometerSetupVC.h"
#import "SPTAcclerometerRecordVC.h"
#import "ATAccelerometerMotionManager.h"
#import "SPTScatterPlotGraph.h"
#import "ATSensorData.h"
#import "SPTConstants.h"
#import <Google/Analytics.h>

@import CoreMotion;

@interface SPTAccelerometerVC() <SPTAccelerometerVCProtocol, MFMailComposeViewControllerDelegate, ATAccelerometerMotionManagerDelegate, CPTPlotDataSource, UIPopoverPresentationControllerDelegate>

// Bar button icons accessors
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startStopSensorUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *setupUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *recordUIB;

// Graph view accessors
@property (weak, nonatomic) IBOutlet CPTGraphHostingView *plotAreaGHV;

// Label to shwo different results
@property (weak, nonatomic) IBOutlet UILabel *displayBoardUIL;

// Accelerometer Manager.
@property (strong, nonatomic) ATAccelerometerMotionManager *motionManager;
@property (atomic) BOOL updatesAreInProgress; // Maintain if test was running
@property (strong, nonatomic) NSNumber *refreshRateHz; // Test refesh rate in Hz
@property (strong, nonatomic) NSMutableArray *dataArray; // Data result is here
@property (strong, nonatomic) id<GAITracker> gaTracker;


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
        self.displayBoardUIL.text = @"Accelerometer not available.";
        self.displayBoardUIL.textAlignment = NSTextAlignmentCenter;
    } else {
        self.displayBoardUIL.text = @"-";
    }
    
    if (![CMSensorRecorder isAccelerometerRecordingAvailable]) {
        UIBarButtonItem *l1 = self.navigationItem.leftBarButtonItems[0];
        UIBarButtonItem *l2 = self.navigationItem.leftBarButtonItems[1];
        self.navigationItem.leftBarButtonItems = [[NSArray alloc] initWithObjects: l1, l2, nil];
    }

    self.refreshRateHz = self.motionManager.refreshRateHz;
    self.dataArray = [[NSMutableArray alloc] init];
    
    // Setup graph area
    [self setupAccelerometerGraph];
    
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
    [self.gaTracker set:kGAIScreenName value:kATAcceleroVC];
    [self.gaTracker send:[[GAIDictionaryBuilder createScreenView] build]];
    // [END screen_view_hit_objc]
    
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
        
        // Track the start test event
        [self.gaTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Test" action:@"Start" label:@"Accelero" value:@1] build]];
        
    } else {
        sender.image = [UIImage imageNamed:@"go25x25"];
        [self.motionManager stopAccelerometerUpdates];
    }
}

#pragma mark - ATSMotionAccelerometerManagerDelegate handlers
- (void) didFinishAccelerometerUpdateWithResults:(NSArray *) results maxSampleValue: (NSNumber *) max minSampleValue:(NSNumber *) min {
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
    [self.accelerometerScatterGraph adjustYAxisMinValue:min length:length];
    
    
    // Reload the data inplotspace
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.accelerometerScatterGraph.defaultPlotSpace;
    [plotSpace.graph reloadData];
}

- (void) accelerometerError: (NSError *) error {
    self.displayBoardUIL.text = [NSString stringWithFormat:@"%@", error.localizedDescription];
}

- (void) accelerometerProgressUpdate: (UInt32) count {
    self.displayBoardUIL.text = [NSString stringWithFormat:@"%u",(unsigned int)count];
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
    
    // We may reach here if app was sent to background.
    self.startStopSensorUIB.image = [UIImage imageNamed:@"go25x25"];
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
            // Track the email sent event
            [self.gaTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Email" action:@"Sent" label:@"Accelero" value:@1] build]];
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
    if ([segue.identifier isEqualToString:@"accelBtnToSetupSegue"] ) {
        SPTAccelerometerSetupVC *setupVC = segue.destinationViewController;
        setupVC.title = @"Setup Accelerometer";
        setupVC.refreshRateHz = [NSNumber numberWithFloat:self.refreshRateHz.doubleValue];
        setupVC.countOfTestDataValues = [self.motionManager savedCountOfAcclerometerDataPoints];
        setupVC.delegate = self;
    } else if ([segue.identifier isEqualToString:@"acceleroRecordPopoverSegue"] ) {
        SPTAcclerometerRecordVC *recordVC = segue.destinationViewController;
        recordVC.popoverPresentationController.delegate = self;
        recordVC.modalPresentationStyle = UIModalPresentationPopover;
        
    }
}


- (IBAction) accelerometerRecordData:(UIStoryboardSegue *)segue {
    NSLog(@"Returning from: %@ -- start recording", segue.identifier);
    // Accessed if start recording was pressed.
}

#pragma mark - Popover delegates
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    // Ensure size to Popover as in storyboard.
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    // Need this to work on iPhone 6S. Stack overflow discussion:
    // http://stackoverflow.com/questions/31275151/why-isnt-preferredcontentsize-used-by-iphone-6-plus-landscape
    
    return UIModalPresentationNone;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    // Get data from popover back. Do nothing for now. For future.
    // SPTAcclerometerRecordVC *recordVC = popoverPresentationController.contentViewController;
    // Access data directly.
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    return YES;
}

#pragma mark - Graph Area

- (void) setupAccelerometerGraph {
    // Get a graphs object
    self.accelerometerScatterGraph = [[SPTScatterPlotGraph alloc]initWithFrame:self.plotAreaGHV.bounds andTitle:@"Times G"];
    
    // Add it to the view
    self.plotAreaGHV.hostedGraph = self.accelerometerScatterGraph;
    
    // Setup x-Axis for Accelero
    NSNumber *xMin = [NSNumber numberWithDouble:kATxAxisMinimumAccelero];
    NSNumber *xLength = [NSNumber numberWithDouble:kATxAxisLengthOnScreenAccelero];
    NSNumber *xMajor = [NSNumber numberWithDouble:kATxAxisIntervalAccelero];
    [self.accelerometerScatterGraph adjustXAxisRange:xMin length:xLength interval:xMajor ticksPerInterval:kATxAxisTicksInIntervalAccelero];
    
    // Setup y-Axis for Accelero
    NSNumber *yMin = [NSNumber numberWithDouble:kATyAxisMinimumAccelero];
    NSNumber *yLength = [NSNumber numberWithDouble:kATyAxisLengthAccelero];
    NSNumber *yMajor = [NSNumber numberWithDouble:kATyAxisIntervalAccelero];
    [self.accelerometerScatterGraph adjustYAxisRange:yMin length:yLength interval:yMajor ticksPerInterval:kATyAxisTicksInIntervalAccelero];
    
    
    // Add scatter plot lines for X,Y,Z and RMS.
    [self.accelerometerScatterGraph addScatterPlotX:self];
    [self.accelerometerScatterGraph addScatterPlotY:self];
    [self.accelerometerScatterGraph addScatterPlotZ:self];
    [self.accelerometerScatterGraph addScatterPlotAvg:self];
    
    // Add legend after all scatter plots have been added
    [self.accelerometerScatterGraph addLegendWithXPadding:-10 withYPadding:-10];
}


#pragma mark - Graph Data

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
                double gValue = sqrt( (data.x*data.x) + (data.y*data.y) + (data.z*data.z));
                return [NSNumber numberWithDouble:gValue];
            } else {
                return @0;
            }
    }
}

#pragma mark - Handle app background event
- (void) appEnteredBackgroundMode: (UIApplication *)application {
    [self.motionManager stopAccelerometerUpdates];
}

@end
