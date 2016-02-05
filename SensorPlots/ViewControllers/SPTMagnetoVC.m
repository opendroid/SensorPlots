//
//  SPTMagnetoVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "SPTMagnetoVC.h"
#import "SPTMagnetoSetupVC.h"
#import "ATMagnetoMotionManager.h"
#import "SPTScatterPlotGraph.h"

@interface SPTMagnetoVC() <SPTMagnetoVCProtocol, MFMailComposeViewControllerDelegate, ATMagnetoMotionManagerDelegate, CPTPlotDataSource>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startStopSensorUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *setupUIB;

@property (weak, nonatomic) IBOutlet CPTGraphHostingView *plotAreaGHV;
@property (weak, nonatomic) IBOutlet UILabel *displayBoardUIL;

// Magneto Manager.
@property (strong, nonatomic) ATMagnetoMotionManager *motionManager;
@property (atomic) BOOL updatesAreInProgress; // Maintain if test was running
@property (strong, nonatomic) NSNumber *refreshRateHz; // Test refesh rate in Hz
@property (strong, nonatomic) NSMutableArray *dataArray; // Data result is here

// Handy accessor for plaotSpace
@property (strong, nonatomic) SPTScatterPlotGraph *magnetoScatterGraph;

@end

@implementation SPTMagnetoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.updatesAreInProgress = NO;
    self.motionManager = [[ATMagnetoMotionManager alloc] init];
    self.motionManager.delegate = self;
    if (!self.motionManager.isMagnetometerAvailable) {
        self.composeUIB.enabled = NO;
        self.trashUIB.enabled = NO;
        self.setupUIB.enabled = NO;
        self.startStopSensorUIB.enabled = NO;
        self.displayBoardUIL.text = @"No Magnetometer available on device.";
        self.displayBoardUIL.textAlignment = NSTextAlignmentCenter;
    }
    
    self.displayBoardUIL.text = @"-";
    self.refreshRateHz = self.motionManager.refreshRateHz;
    self.dataArray = [[NSMutableArray alloc] init];
    
    // Setup graph area
    [self setupMagnetoGraph];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Button Handlers
- (IBAction)emailMagnetoDataHandler:(UIBarButtonItem *)sender {
    // Check if there is data in 'MagnetometerData' to send.
    
    NSNumber *itemsCount = self.motionManager.savedCountOfMagnetoDataPoints;
    if (itemsCount.integerValue < 1) {
        self.displayBoardUIL.text = [NSString stringWithFormat:@"No data to email"];
        return;
    }
    
    // Present mail view controller on screen;
    MFMailComposeViewController *mc = [self.motionManager emailComposerWithMagnetoData];
    mc.mailComposeDelegate = self;
    @try {
        [self presentViewController:mc animated:YES completion:NULL];
    }
    @catch (NSException *exception) {
        self.displayBoardUIL.text = [NSString stringWithFormat:@"No email viewer."];
    }
}

- (IBAction)trashMagnetoDataHandler:(UIBarButtonItem *)sender {
    [self.motionManager trashMagnetoStoredData];
}

- (IBAction)startStopCapturingMagnetoHandler:(UIBarButtonItem *)sender {
    if (! self.updatesAreInProgress) {
        sender.image = [UIImage imageNamed:@"hand25x25"];
        self.updatesAreInProgress = YES;
        // Disable other buttons while test in progress.
        self.composeUIB.enabled = NO;
        self.trashUIB.enabled = NO;
        self.setupUIB.enabled = NO;
        [self.motionManager startMagnetoUpdates];
        
    } else {
        sender.image = [UIImage imageNamed:@"go25x25"];
        [self.motionManager stopMagnetoUpdates];
    }
}

#pragma mark - ATSMotionMagnetoManagerDelegate handlers
- (void) didFinishMagnetoUpdateWithResults: (NSArray *) results {
    [self.dataArray addObjectsFromArray:results];
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.magnetoScatterGraph.defaultPlotSpace;
    [plotSpace.graph reloadData];
}

- (void) magnetoError: (NSError *) error {
    self.displayBoardUIL.text = [NSString stringWithFormat:@"%@", error.localizedDescription];
}

- (void) magnetoProgressUpdate: (UInt32) count {
    self.displayBoardUIL.text = [NSString stringWithFormat:@"%u",count];
}

- (void) didTrashMagnetoMagnetoCache {
    self.displayBoardUIL.text = @"Deleted stored data";
}

- (void)didStopMagnetoUpdate {
    // Enable other buttons while test in progress.
    self.composeUIB.enabled = YES;
    self.trashUIB.enabled = YES;
    self.setupUIB.enabled = YES;
    self.updatesAreInProgress = NO;
    
    [self.dataArray removeAllObjects];
}

#pragma mark - SPTMagnetoVCProtocol handlers

// Get config data from the Setup controller
- (void)receiveMagnetoRefreshRateHz:(NSNumber *)value {
    // Pass the data along to the model
    self.refreshRateHz = [self.motionManager magnetoUpdateInterval:value];
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
    SPTMagnetoSetupVC *setupVC = segue.destinationViewController;
    setupVC.title = @"Setup Magneto";
    setupVC.refreshRateHz = [NSNumber numberWithFloat:self.refreshRateHz.doubleValue];
    setupVC.countOfTestDataValues = [self.motionManager savedCountOfMagnetoDataPoints];
    setupVC.delegate = self;
}

#pragma mark - Magneto Graph View Area

- (void) setupMagnetoGraph {
    // Get a graphs object
    self.magnetoScatterGraph = [[SPTScatterPlotGraph alloc]initWithFrame:self.plotAreaGHV.bounds andTitle:@"Micro Tesla"];
    
    // Add it to the view
    self.plotAreaGHV.hostedGraph = self.magnetoScatterGraph;
    
    // Setup Axis for Magneto
    [self.magnetoScatterGraph adjustXAxisRange:@-30.0 length:@330.0 interval:@50.0 ticksPerInterval:1];
    [self.magnetoScatterGraph adjustYAxisRange:@-500 length:@1000 interval:@100.0 ticksPerInterval:1];
    
    
    // Add scatter plot lines for X,Y,Z and RMS.
    [self.magnetoScatterGraph addScatterPlotX:self];
    [self.magnetoScatterGraph addScatterPlotY:self];
    [self.magnetoScatterGraph addScatterPlotZ:self];
    [self.magnetoScatterGraph addScatterPlotAvg:self];
    
    // Add legend after all scatter plots have been added
    [self.magnetoScatterGraph addLegendWithXPadding:-(self.view.bounds.size.width / 20) withYPadding:(self.view.bounds.size.height / 40)];
    self.magnetoScatterGraph.legendAnchor = CPTRectAnchorBottomRight;
    
}


#pragma mark - Magneto Graph Data

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return self.dataArray.count;
}

- (id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx {
    CMMagnetometerData *data = [self.dataArray objectAtIndex:idx];
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            return [NSNumber numberWithUnsignedLong:idx];
            
        default: // CPTScatterPlotFieldY values, the identifiers are hardcoded in SPTScatterPlotGraph
            if ([plot.identifier isEqual:@"X"]) {
                return [NSNumber numberWithDouble:data.magneticField.x];
            } else if ([plot.identifier isEqual:@"Y"]) {
                return [NSNumber numberWithDouble:data.magneticField.y];
            } else if ([plot.identifier isEqual:@"Z"]) {
                return [NSNumber numberWithDouble:data.magneticField.z];
            } else if ([plot.identifier isEqual:@"A"]) {
                double rmsValue = sqrt( (data.magneticField.x*data.magneticField.x) + (data.magneticField.y*data.magneticField.y) + (data.magneticField.z*data.magneticField.z));
                return [NSNumber numberWithDouble:rmsValue];
            } else {
                return @0;
            }
    }
}

@end
