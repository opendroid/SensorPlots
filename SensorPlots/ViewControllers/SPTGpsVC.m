//
//  SPTGpsVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 3/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "SPTGpsVC.h"
#import "SPTConstants.h"
#import "AppDelegate.h"
#import "LocationData+CoreDataClass.h"
#import "ATOUtilities.h"
#import <Google/Analytics.h>

@import CoreLocation;
@import MapKit;
@import MessageUI;

@interface SPTGpsVC() <CLLocationManagerDelegate, MFMailComposeViewControllerDelegate, MKMapViewDelegate>

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
@property (atomic) BOOL  isBackgroundEnabled; // Is background mode on
@property (atomic) NSUInteger countOfUpdates;
@property (strong, nonatomic) NSMutableArray<id<MKOverlay>> *overlays;
@property (nonatomic) MKMapType mapType;
@property (strong, nonatomic) NSArray *tripLineColors;
@end

@implementation SPTGpsVC

- (void)viewDidLoad {
    [super viewDidLoad];

    
    // Setup MOC -- managed object contect first
    AppDelegate *appDelegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    // Setup location manager
    [self initializeLocationServices];
    self.displayBoardUIL.text = @"";
    self.countOfUpdates = 0;
    
    // Setup map infrsatructure if available.
    self.gpsUpdatesMMV.delegate = self;
    NSNumber *mType = [[[NSUserDefaults standardUserDefaults] objectForKey:kATGpsConfigKey] objectForKey:kATMapTypeConfigKey];
    if (mType != nil) {
        self.mapType = mType.integerValue;
    } else {
        self.mapType = MKMapTypeStandard;
    }
    self.gpsUpdatesMMV.showsUserLocation = TRUE;
    self.gpsUpdatesMMV.showsScale = TRUE;
    self.gpsUpdatesMMV.showsCompass = TRUE;
    self.gpsUpdatesMMV.showsTraffic = TRUE;
    self.gpsUpdatesMMV.showsBuildings = TRUE;
    self.gpsUpdatesMMV.userTrackingMode = MKUserTrackingModeFollow;

    // Update map with historic trips.
    self.tripLineColors = @[[UIColor blueColor], [UIColor greenColor], [UIColor grayColor],
                            [UIColor redColor], [UIColor purpleColor], [UIColor magentaColor],
                            [UIColor darkGrayColor], [UIColor brownColor], [UIColor cyanColor]];
    self.overlays = nil; // All overlays are stored in this array. Beware
    [self updateMapConfig];
    [self updateMap];
    
    // Listen to app going to background.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(appEnteredBackgroundMode:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    // Observe for changes in Map display type.
    // Note that the 'SPTGpsConfiguration.SPTMapTypeConfiguration' causes crash
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:kATGpsConfigKey
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    // set up GA
    self.gaTracker = [[GAI sharedInstance] defaultTracker];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Update config. Don't redraw map. User may be playing with zoom levels
    [self updateMapConfig];
    
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

- (void)receiveGpsSetupData:(NSDictionary *)configData {
    [self saveGpsConfig:configData];
    [self locationManagerUpdateConfiguration]; // Update the configuration
    [self updateMapConfig]; // Update map configuration.
    
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
    NSDictionary *gpsConfig = [ATOUtilities getGpsConfigurationFromNSU];
    CLLocationDistance distanceFilter = [[gpsConfig objectForKey:kATGpsUpdateKey] doubleValue];
    CLActivityType activityType = [[gpsConfig objectForKey:kATGpsActivityKey] integerValue];
    CLLocationAccuracy desiredAccuracy = [[gpsConfig objectForKey:kATGpsAccuracyKey] doubleValue];
    
    self.isBackgroundEnabled = [[gpsConfig objectForKey:kATGpsIsBackgroundOnKey] boolValue];
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
    if (! self.updatesAreInProgress) { // User pressed 'start updated'
        [self locationManagerUpdateConfiguration];
        sender.image = [UIImage imageNamed:@"hand25x25"];
        self.updatesAreInProgress = YES;
        // Disable other buttons while test in progress.
        self.composeUIB.enabled = NO;
        self.trashUIB.enabled = NO;
        self.setupUIB.enabled = NO;
        self.countOfUpdates = 0;
        if (IS_OS_9_OR_LATER) { // Required after 9.0 for background locatio to run.
            self.locationManager.allowsBackgroundLocationUpdates = YES;
        }
        [self.locationManager startUpdatingLocation];
        // Send start a test notification
        [self.gaTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Test" action:@"Start" label:@"GPS" value:@1] build]];
        self.displayBoardUIL.text = @"GPS Points: 0";
    } else { // User pressed 'stop updated'
        [self stopLocationUpdates];
        [self updateMap]; // Test is stopped update the map.
    }
}

- (void) stopLocationUpdates {
    self.startStopGpsUIB.image = [UIImage imageNamed:@"go25x25"];
    [self.locationManager stopUpdatingLocation];
    self.updatesAreInProgress = NO;
    self.composeUIB.enabled = YES;
    self.trashUIB.enabled = YES;
    self.setupUIB.enabled = YES;
    if (IS_OS_9_OR_LATER) {
        self.locationManager.allowsBackgroundLocationUpdates = NO;
    }
}

- (IBAction)trashGpsDataHandler:(UIBarButtonItem *)sender {
    // 1. Delete core data
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"LocationData"];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    AppDelegate *app = (AppDelegate *) [UIApplication sharedApplication].delegate;
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
    
    NSNumber *itemsCount = [ATOUtilities savedCountOfLocationDataPoints];
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
    [coreDataString appendString:@"latitude,longitude,altitude,verticalAccuracy,horizontalAccuracy,course,speedMPH,timestamp\n"];
    
    // Extract the data
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSSSSS Z";
    for (LocationData *d in results) {
        NSString *dateTime = [formatter stringFromDate:d.timestamp];
        NSString *rowData = [NSString stringWithFormat:@"%f,%f,%f,%f,%f,%f,%f,%@\n",
                             d.latitude.doubleValue, d.longitude.doubleValue, d.altitude.doubleValue,
                             d.verticalAccuracy.doubleValue, d.horizontalAccuracy.doubleValue,
                             d.course.doubleValue, d.speed.doubleValue*kATMetersPerSecToMPH,dateTime];
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
    if (results.count < 2) return; // Nothing to show in DB
    
    // Clean up Overlays.
    if (self.overlays) {
        [self.gpsUpdatesMMV removeOverlays:self.overlays];
        [self.overlays removeAllObjects];
    } else {
        self.overlays = [[NSMutableArray alloc] init];
    }
    
    CLLocationCoordinate2D coordinates[results.count];
    MKMapPoint points[results.count]; //C array of MKMapPoint struct
    for (int i=0; i < results.count; i++) {
        double latitude = results[i].latitude.doubleValue;
        double longitude = results[i].longitude.doubleValue;
        coordinates[i]  = CLLocationCoordinate2DMake(latitude, longitude);
        points[i] = MKMapPointForCoordinate(coordinates[i]); // For bounded rectable
    }
    // Create Overlay arrays for points that are no more than a 100 meters apart
    // That is about 22 second update at 100 mph
    int polylineBeginIdx = 0, idx;
    MKMapPoint pointA, pointB;
    for (idx=1; idx < results.count; idx++) {
        pointA = points[idx-1];
        pointB = points[idx];
        CLLocationDistance distance = MKMetersBetweenMapPoints(pointA,pointB);
        if (distance > 1000) {
            MKPolyline *path = [MKPolyline polylineWithCoordinates:coordinates+polylineBeginIdx count:idx-polylineBeginIdx];
            path.title = [NSString stringWithFormat:@"%ld",(long)self.overlays.count+1];
            [self.overlays addObject:path];
            polylineBeginIdx = idx;
        }
    }
    NSLog(@"Out: polylineBeginIdx:%d, idx:%d", polylineBeginIdx, idx);
    // Add last polyline
    if (polylineBeginIdx < idx) {
        MKPolyline *path = [MKPolyline polylineWithCoordinates:coordinates+polylineBeginIdx count:idx-polylineBeginIdx];
        path.title = [NSString stringWithFormat:@"%ld",(long)self.overlays.count+1];
        [self.overlays addObject:path];
    }
    // If no overlays were added -- make one overlay with all points
    if (self.overlays.count < 1) {
        MKPolyline *path = [MKPolyline polylineWithCoordinates:coordinates count:results.count];
        path.title = @"1";
        [self.overlays addObject:path];
    }
    
    // Add to graph
    [self.gpsUpdatesMMV addOverlays:self.overlays];
    NSLog(@"Added overlays:%ld", (unsigned long)self.overlays.count);
    
    // Setup visible region for map.
    MKMapRect mapRect = [[MKPolygon polygonWithPoints:points count:results.count] boundingMapRect];
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
    [self.gpsUpdatesMMV setRegion:region animated:YES];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer* lineView = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        lineView.lineWidth = 5;
        // Extract color from title
        UIColor *color = [self.tripLineColors objectAtIndex:overlay.title.intValue%self.tripLineColors.count];
        lineView.strokeColor = [color colorWithAlphaComponent:0.7];
        lineView.fillColor = [color colorWithAlphaComponent:0.2];
        return lineView;
    }
    return nil;
}

- (void) updateMapConfig {
    NSDictionary *gpsConfig = [ATOUtilities getGpsConfigurationFromNSU];
    MKMapType mapType = [[gpsConfig objectForKey:kATMapTypeConfigKey] integerValue];
    self.gpsUpdatesMMV.mapType = mapType;
}

#pragma mark - Listening to changes in Map type
// Only change map type when updated
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:kATGpsConfigKey]) {
        // Interested in map type change
        NSDictionary *newData = [change objectForKey:NSKeyValueChangeNewKey];
        if (newData != nil) {
            NSNumber *newMapType = [newData objectForKey:kATMapTypeConfigKey];
            if (newMapType != nil) {
                if (self.mapType != newMapType.integerValue) {
                    [self updateMapConfig];
                    self.mapType = newMapType.integerValue;
                }
            } // end 'newMapType != nil'
        }
    }
}

#pragma mark - Handle app background event
- (void) appEnteredBackgroundMode: (UIApplication *)application {
    NSDictionary *gpsConfig = [ATOUtilities getGpsConfigurationFromNSU];
    self.isBackgroundEnabled = [[gpsConfig objectForKey:kATGpsIsBackgroundOnKey] boolValue];
    if (self.isBackgroundEnabled == NO)
        [self stopLocationUpdates];
}

#pragma mark - Segue Handlers
// Pass data to child setup controller.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"SPTGpsVC:prepareForSegue:%@", segue.identifier);
}

- (IBAction)unwindToSPTGpsVC:(UIStoryboardSegue *)segue {
    NSLog(@"SPTGpsVC:unwindToSPTGpsVC:%@", segue.identifier);
}

@end
