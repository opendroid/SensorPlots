//
//  SPTGyroVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/2/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "SPTGyroVC.h"
#import "SPTGyroSetupVC.h"
#import "ATGyroMotionManager.h"
#import "SPTScatterPlotGraph.h"

@interface SPTGyroVC() <SPTGyroVCProtocol, MFMailComposeViewControllerDelegate, ATGyroMotionManagerDelegate, CPTPlotDataSource>


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
@property (strong, nonatomic) NSMutableArray *dataArray; // Data result is here

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
        self.displayBoardUIL.text = @"No Gyro available on device.";
        self.displayBoardUIL.textAlignment = NSTextAlignmentCenter;
    }
    
    self.displayBoardUIL.text = @"-";
    self.refreshRateHz = self.motionManager.refreshRateHz;
    self.dataArray = [[NSMutableArray alloc] init];
    
    // Setup graph area
    [self setupGyroGraph];
    
    // Listen to app going to background.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(appEnteredBackgroundMode:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
        [self.motionManager startGyroUpdates];
        
    } else {
        sender.image = [UIImage imageNamed:@"go25x25"];
        [self.motionManager stopGyroUpdates];
    }
}

#pragma mark - ATSMotionGyroManagerDelegate handlers
- (void) didFinishGyroUpdateWithResults: (NSArray *) results {
    [self.dataArray addObjectsFromArray:results];
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.gyroScatterGraph.defaultPlotSpace;
    [plotSpace.graph reloadData];
}

- (void) gyroError: (NSError *) error {
    self.displayBoardUIL.text = [NSString stringWithFormat:@"%@", error.localizedDescription];
}

- (void) gyroProgressUpdate: (UInt32) count {
    self.displayBoardUIL.text = [NSString stringWithFormat:@"%u",count];
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
    [self.dataArray removeAllObjects];
}

#pragma mark - SPTGyroVCProtocol handlers

// Get config data from the Setup controller
- (void)receiveGyroRefreshRateHz:(NSNumber *)value {
    // Pass the data along to the model
    self.refreshRateHz = [self.motionManager gyroUpdateInterval:value];
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
// Pass data to child setup controller.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    SPTGyroSetupVC *setupVC = segue.destinationViewController;
    setupVC.title = @"Setup Gyro";
    setupVC.refreshRateHz = [NSNumber numberWithFloat:self.refreshRateHz.doubleValue];
    setupVC.countOfTestDataValues = [self.motionManager savedCountOfGyroDataPoints];
    setupVC.delegate = self;
}

#pragma mark - Gyro Graph View Area

- (void) setupGyroGraph {
    // Get a graphs object
    self.gyroScatterGraph = [[SPTScatterPlotGraph alloc]initWithFrame:self.plotAreaGHV.bounds andTitle:@"Rad/sec RHS"];
    
    // Add it to the view
    self.plotAreaGHV.hostedGraph = self.gyroScatterGraph;

    // Setup Axis for Gyro
    [self.gyroScatterGraph adjustXAxisRange:@-20.0 length:@325.0 interval:@25.0 ticksPerInterval:2];
    [self.gyroScatterGraph adjustYAxisRange:@-20 length:@40 interval:@10.0 ticksPerInterval:1];
    
    
    // Add scatter plot lines for X,Y,Z and RMS.
    [self.gyroScatterGraph addScatterPlotX:self];
    [self.gyroScatterGraph addScatterPlotY:self];
    [self.gyroScatterGraph addScatterPlotZ:self];
    [self.gyroScatterGraph addScatterPlotAvg:self];
    
    // Add legend after all scatter plots have been added
    [self.gyroScatterGraph addLegendWithXPadding:-(self.view.bounds.size.width / 20) withYPadding:(self.view.bounds.size.height / 40)];
    self.gyroScatterGraph.legendAnchor = CPTRectAnchorBottomRight;

}


#pragma mark - Gyro Graph Data

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return self.dataArray.count;
}

- (id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx {
    CMGyroData *data = [self.dataArray objectAtIndex:idx];
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            return [NSNumber numberWithUnsignedLong:idx];
            
        default: // CPTScatterPlotFieldY values, the identifiers are hardcoded in SPTScatterPlotGraph
            if ([plot.identifier isEqual:@"X"]) {
                return [NSNumber numberWithDouble:data.rotationRate.x];
            } else if ([plot.identifier isEqual:@"Y"]) {
                return [NSNumber numberWithDouble:data.rotationRate.y];
            } else if ([plot.identifier isEqual:@"Z"]) {
                return [NSNumber numberWithDouble:data.rotationRate.z];
            } else if ([plot.identifier isEqual:@"A"]) {
                double rmsValue = sqrt( (data.rotationRate.x*data.rotationRate.x) + (data.rotationRate.y*data.rotationRate.y) + (data.rotationRate.z*data.rotationRate.z));
                return [NSNumber numberWithDouble:rmsValue];
            } else {
                return @0;
            }
    }
}

#pragma mark - Handle app background event
- (void) appEnteredBackgroundMode: (UIApplication *)application {
    [self.motionManager stopGyroUpdates];
}

@end
