//
//  SPTGpsVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 3/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "SPTGpsVC.h"
#import "SPTGpsSetupVC.h"
#import "SPTConstants.h"
#import "AppDelegate.h"
#import "LocationData.h"
#import "ATOUtilities.h"
#import <Google/Analytics.h>

@import CoreLocation;
@import MapKit;
@import MessageUI;

@interface SPTGpsVC() <SPTGpsVCProtocol, CLLocationManagerDelegate, MFMailComposeViewControllerDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startStopGpsUIB;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *setupUIB;
@property (weak, nonatomic) IBOutlet UILabel *displayBoardUIL;
@property (weak, nonatomic) IBOutlet MKMapView *gpsUpdatesMMV;

@property (strong, nonatomic) id<GAITracker> gaTracker;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (atomic) BOOL updatesAreInProgress; // Maintain if test was running
@property (atomic) NSUInteger countOfUpdates;
@property (strong, nonatomic) MKPolyline *path;

@end

@implementation SPTGpsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Setup location manager
    [self initializeLocationServices];
    self.displayBoardUIL.text = @"";
    self.countOfUpdates = 0;
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    // Show goodies on map if available.
    self.path = nil;
    self.gpsUpdatesMMV.delegate = self;
    [self updateMapConfig];
    [self updateMap];
    
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
    [self.gaTracker set:kGAIScreenName value:kATGpsVC];
    [self.gaTracker send:[[GAIDictionaryBuilder createScreenView] build]];
    // [END screen_view_hit_objc]
}

#pragma mark - Configuration Management
- (void) saveGpsConfig: (NSDictionary *) configData {
    [[NSUserDefaults standardUserDefaults] setObject:configData forKey:kATGpsConfigKey];
}

- (NSDictionary *) getGpsConfigurationFromNSU {
    NSDictionary *gpsConfig =  [[NSUserDefaults standardUserDefaults] objectForKey:kATGpsConfigKey];
    if (!gpsConfig) {
        // Set up defaults if no data is available.
        gpsConfig = [NSDictionary dictionaryWithObjectsAndKeys:
                     [NSNumber numberWithBool:FALSE], kATGpsIsBackgroundOnKey,
                     [NSNumber numberWithDouble:100.0], kATGpsUpdateKey,
                     @"100.0 Mts", kATGpsUpdateUILKey,
                     [NSNumber numberWithDouble:kCLLocationAccuracyBest], kATGpsAccuracyKey,
                     [NSNumber numberWithDouble:1.5], kATGpsAccuracyUISKey,
                     @"Best", kATGpsAccuracyUILKey,
                     [NSNumber numberWithInteger:CLActivityTypeAutomotiveNavigation], kATGpsActivityKey,
                     [NSNumber numberWithDouble:2.5], kATGpsActivityUISKey,
                     [NSNumber numberWithInteger:MKMapTypeStandard], kATMapTypeConfigKey,
                     @"Auto Navigation", kATGpsActivityUILKey,
                     nil];
        [self saveGpsConfig:gpsConfig];
    }
    return gpsConfig;
}


- (void)receiveGpsSetupData:(NSDictionary *)configData {
    [self saveGpsConfig:configData];
    [self locationManagerUpdateConfiguration]; // Update the configuration
    [self updateMapConfig]; // Update map configuration.
    
}

#pragma mark - Segue Handlers
// Pass data to child setup controller.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    SPTGpsSetupVC *setupVC = segue.destinationViewController;
    setupVC.title = @"Setup GPS";
    // Create a Mutable copy of dictionary
    setupVC.configurationData = [[self getGpsConfigurationFromNSU] mutableCopy];
    setupVC.countOfLocationPoints = [self savedCountOfGpsDataPoints];
    setupVC.delegate = self;
}

#pragma mark - Location Manager Setup
- (void) initializeLocationServices {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    if (IS_OS_8_OR_LATER && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestAlwaysAuthorization];
    }
    [self locationManagerUpdateConfiguration];
    [self setupGoButton];
}

// Manage auth status
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self setupGoButton];
}

// Set up the configuration for the location manager
- (void) locationManagerUpdateConfiguration {
    NSDictionary *gpsConfig = [self getGpsConfigurationFromNSU];
    CLLocationDistance distanceFilter = [[gpsConfig objectForKey:kATGpsUpdateKey] doubleValue];
    CLActivityType activityType = [[gpsConfig objectForKey:kATGpsActivityKey] integerValue];
    CLLocationAccuracy desiredAccuracy = [[gpsConfig objectForKey:kATGpsAccuracyKey] doubleValue];
    
    self.locationManager.distanceFilter = distanceFilter;
    self.locationManager.activityType = activityType;
    self.locationManager.desiredAccuracy = desiredAccuracy;
}

- (void) setupGoButton {
    if (IS_OS_42_OR_LATER) { // Only available since 4.2
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if ( (status == kCLAuthorizationStatusNotDetermined) || (status == kCLAuthorizationStatusDenied) ) {
            self.startStopGpsUIB.enabled = NO;
            return;
        }
    }
    self.startStopGpsUIB.enabled = YES;
}

#pragma mark - Location Manager UX Handlers
- (IBAction)startStopCapturingGpsHandler:(UIBarButtonItem *)sender {
    if (! self.updatesAreInProgress) {
        sender.image = [UIImage imageNamed:@"hand25x25"];
        self.updatesAreInProgress = YES;
        // Disable other buttons while test in progress.
        self.composeUIB.enabled = NO;
        self.trashUIB.enabled = NO;
        self.setupUIB.enabled = NO;
        self.countOfUpdates = 0;
        [self.locationManager startUpdatingLocation];
        // Send start a test notification
        [self.gaTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Test" action:@"Start" label:@"GPS" value:@1] build]];
        self.displayBoardUIL.text = @"GPS Points: 0";
    } else {
        sender.image = [UIImage imageNamed:@"go25x25"];
        [self.locationManager stopUpdatingLocation];
        self.updatesAreInProgress = NO;
        self.composeUIB.enabled = YES;
        self.trashUIB.enabled = YES;
        self.setupUIB.enabled = YES;
        
        // Test is stopped update the map.
        [self updateMap];
    }
}

- (IBAction)trashGpsDataHandler:(UIBarButtonItem *)sender {
    // 1. Delete core data
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"LocationData"];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    AppDelegate *app = [UIApplication sharedApplication].delegate;
    NSError *deleteError = nil;
    [app.persistentStoreCoordinator executeRequest:delete withContext:self.managedObjectContext error:&deleteError];
    if (deleteError) {
        self.displayBoardUIL.text = [NSString stringWithFormat:@"Delete error: %@",deleteError.localizedDescription];
    }
    
    [self.managedObjectContext save:&deleteError];
    if (deleteError) {
        self.displayBoardUIL.text = [NSString stringWithFormat:@"Delete error: %@",deleteError.localizedDescription];
    }
    
    // 2. Clear .csv file if created for email purposes
    NSString *filePathName = [ATOUtilities createDataFilePathForName:kATCSVDataFilenameGps];
    [[NSFileManager defaultManager] removeItemAtPath:filePathName error:&deleteError];
    if (deleteError) {
        self.displayBoardUIL.text = [NSString stringWithFormat:@"Delete error: %@",deleteError.localizedDescription];
    }
    self.displayBoardUIL.text = @"Location data deleted.";
}

- (IBAction)emailGpsDataHandler:(UIBarButtonItem *)sender {
    // Check if there is data in 'AccelerometerData' to send.
    
    NSNumber *itemsCount = [self savedCountOfGpsDataPoints];
    if (itemsCount.integerValue < 1) {
        self.displayBoardUIL.text = [NSString stringWithFormat:@"No data to email"];
        return;
    }
    
    // Present mail view controller on screen;
    MFMailComposeViewController *mc = [self emailComposerWithLocationsData];
    mc.mailComposeDelegate = self;
    @try {
        [self presentViewController:mc animated:YES completion:NULL];
    }
    @catch (NSException *exception) {
        self.displayBoardUIL.text = [NSString stringWithFormat:@"No email viewer."];
    }
}

#pragma mark - Location Manager Updates Handlers
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    self.countOfUpdates += locations.count;
    self.displayBoardUIL.text = [NSString stringWithFormat:@"GPS Points: %lu",(unsigned long)self.countOfUpdates];
    
    // GPS update rate is slow once a second, so you can save in this thread.
    [self saveLocationsToCoreData:locations];
}

- (void) saveLocationsToCoreData: (NSArray<CLLocation *> *)locations {

        for (NSUInteger i = locations.count; i > 0 ; i--) {
            CLLocation *d = locations[i-1];
            LocationData *data = [NSEntityDescription insertNewObjectForEntityForName:@"LocationData" inManagedObjectContext:self.managedObjectContext];
            
            // Put data in store
            data.latitude = [NSNumber numberWithDouble:d.coordinate.latitude];
            data.longitude = [NSNumber numberWithDouble:d.coordinate.longitude];
            data.altitude = [NSNumber numberWithDouble:d.altitude];
            data.verticalAccuracy = [NSNumber numberWithDouble:d.verticalAccuracy];
            data.horizontalAccuracy = [NSNumber numberWithDouble:d.horizontalAccuracy];
            data.course = [NSNumber numberWithDouble:d.course];
            data.speed = [NSNumber numberWithDouble:d.speed];
            data.timestamp = d.timestamp; // Time since last phone bootup.
        }
        
        // Save the data
        __block NSError *error;
        BOOL isSaved = [self.managedObjectContext save:&error];
        if (!isSaved) {
                self.displayBoardUIL.text = [NSString stringWithFormat:@"Save error: %@",error.localizedDescription];
        }

}

- (NSNumber *) savedCountOfGpsDataPoints {
    // Check if there is data in 'MagnetoData' to send.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"LocationData"];
    fetchRequest.resultType = NSCountResultType;
    NSError *fetchError = nil;
    NSUInteger itemsCount = [self.managedObjectContext countForFetchRequest:fetchRequest error:&fetchError];
    if (itemsCount == NSNotFound) {
        itemsCount = 0;
    }
    NSNumber *item = [NSNumber numberWithInteger:itemsCount];
    return item;
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
            [self.gaTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Email" action:@"Sent" label:@"Location" value:@1] build]];
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

- (MFMailComposeViewController *) emailComposerWithLocationsData {
    //Get a file name to write the data to using the documents directory:
    NSString *fileName = [ATOUtilities createDataFilePathForName:kATCSVDataFilenameGps];
    
    // Read contents from CoreData table and store in a NSMutableString
    NSMutableString *coreDataString = [[NSMutableString alloc] init];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"LocationData"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    NSError *fetchError;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    [coreDataString appendString:@"latitude,longitude,altitude,verticalAccuracy,horizontalAccuracy,course,speed,timestamp\n"];
    
    // Extract the data
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSSSSS Z";
    for (LocationData *d in results) {
        NSString *dateTime = [formatter stringFromDate:d.timestamp];
        NSString *rowData = [NSString stringWithFormat:@"%f,%f,%f,%f,%f,%f,%f,%@\n", d.latitude.doubleValue, d.longitude.doubleValue, d.altitude.doubleValue, d.verticalAccuracy.doubleValue, d.horizontalAccuracy.doubleValue, d.course.doubleValue, d.speed.doubleValue,dateTime];
        [coreDataString appendString:rowData];
    }
    
    // Save contents to a CSV file.
    [coreDataString writeToFile:fileName  atomically:YES  encoding:NSUTF8StringEncoding error:nil];
    NSData *fileData = [NSData dataWithContentsOfFile:fileName];
    
    // Create the Email message with attachment and compose a viewer
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    [mc setSubject:kATEmailSubjectGps];
    [mc setMessageBody:kATEmailBodyGps isHTML:NO];
    [mc addAttachmentData:fileData mimeType:@"text/csv" fileName:kATCSVDataFilenameGps];
    
    return mc;
}

#pragma mark - Update Map
- (void) updateMap {
    // Get maximum last 100 saved points.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"LocationData"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    fetchRequest.fetchLimit = kATGpsMaxPointsToPlot;
    NSError *fetchError;
    NSArray<LocationData *> *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        self.displayBoardUIL.text = [NSString stringWithFormat:@"Delete error: %@",fetchError.localizedDescription];
        return;
    }
    if (results.count < 1) return; // Nothing to show in DB
    
    if (self.path)
        [self.gpsUpdatesMMV removeOverlay:self.path];

    // Draw thw polyline
    CLLocationCoordinate2D coordinates[results.count];
    MKMapPoint points[results.count]; //C array of MKMapPoint struct
    for (int i =0; i < results.count; i++) {
        double latitude = results[i].latitude.doubleValue;
        double longitude = results[i].longitude.doubleValue;
        coordinates[i]  = CLLocationCoordinate2DMake(latitude, longitude);
        points[i] = MKMapPointForCoordinate(coordinates[i]); // For bounded rectable
    }
    self.path = [MKPolyline polylineWithCoordinates:coordinates count:results.count];
    [self.gpsUpdatesMMV addOverlay:self.path];
    
    // Setup visible region for map.
    MKMapRect mapRect = [[MKPolygon polygonWithPoints:points count:results.count] boundingMapRect];
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
    [self.gpsUpdatesMMV setRegion:region animated:YES];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolylineRenderer* lineView = [[MKPolylineRenderer alloc] initWithPolyline:self.path];
    lineView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
    lineView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
    lineView.lineWidth = 2;
    return lineView;
}

- (void) updateMapConfig {
    self.gpsUpdatesMMV.showsUserLocation = TRUE;
    self.gpsUpdatesMMV.showsScale = TRUE;
    self.gpsUpdatesMMV.showsCompass = TRUE;
    self.gpsUpdatesMMV.showsTraffic = TRUE;
    self.gpsUpdatesMMV.showsBuildings = TRUE;
    
    NSDictionary *gpsConfig = [self getGpsConfigurationFromNSU];
    MKMapType mapType = [[gpsConfig objectForKey:kATMapTypeConfigKey] integerValue];
    self.gpsUpdatesMMV.mapType = mapType;
}

@end
