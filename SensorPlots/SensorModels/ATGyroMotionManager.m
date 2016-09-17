//
//  ATGyroMotionManager.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "ATGyroMotionManager.h"
#import "AppDelegate.h"
#import "GyroData.h"
#import "ATOUtilities.h"
#import "ATSensorData.h"
#import "SPTConstants.h"

@interface ATGyroMotionManager()
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableArray *incomingDataArray; // Incoming data from IOS
@property (strong, nonatomic) NSMutableArray *outgoingDataArray; // Data sent to View Controller
@property (strong, nonatomic) AppDelegate *appDelegate;

@property (atomic) BOOL gyroUpdatesStartedByUser;
@property (atomic) __block BOOL gyroUpdatesStoppedByUser; // Checked in block.
@property (atomic) UInt32 realTimeCountOfGyroDataPoints;
@end

@implementation ATGyroMotionManager

#pragma mark - initializers
- (instancetype) init {
    if (self = [super init]) {
        // Configure App delegate, motion manager and MBO
        self.appDelegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
        if ([self.appDelegate respondsToSelector:@selector(motionManager)]) {
            self.motionManager = [self.appDelegate motionManager];
            if (self.motionManager && !self.refreshRateHz ) {
                self.refreshRateHz = [self getGyroConfigurationInNSU];
                self.motionManager.gyroUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
            }
        }
        self.managedObjectContext = self.appDelegate.managedObjectContext;
    }
    if ((!self.motionManager) || (!self.managedObjectContext)) {
        return nil; // Initilization failed.
    }
    self.gyroUpdatesStoppedByUser = NO;
    self.gyroUpdatesStartedByUser = NO;
    return self;
}

- (instancetype) initWithUpdateInterval: (NSNumber *) updateInterval {
    if (self = [self init]) {
        self.refreshRateHz = [self gyroUpdateInterval:updateInterval];
    }
    
    return self;
}

#pragma mark - Public accesors
- (NSNumber *) savedCountOfGyroDataPoints {
    // Check if there is data in 'GyroData' to send.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"GyroData"];
    fetchRequest.resultType = NSCountResultType;
    NSError *fetchError = nil;
    NSUInteger itemsCount = [self.managedObjectContext countForFetchRequest:fetchRequest error:&fetchError];
    if (itemsCount == NSNotFound) {
        itemsCount = 0;
    }
    NSNumber *item = [NSNumber numberWithInteger:itemsCount];
    return item;
}

- (NSNumber *) gyroUpdateInterval: (NSNumber *) intervalHzWithDouble {

    if (intervalHzWithDouble.doubleValue < 1.0) {
        self.refreshRateHz = [NSNumber numberWithDouble:1.0];
    } else if ( intervalHzWithDouble.doubleValue > 100.00) {
        self.refreshRateHz = [NSNumber numberWithDouble:100.0];
    } else {
        self.refreshRateHz = intervalHzWithDouble;
    }
    self.motionManager.gyroUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
    [self saveGyroConfigurationInNSU:self.refreshRateHz];
    return self.refreshRateHz;
}

- (BOOL) gyroUpdateBackgroundMode: (BOOL) mode {
    [self saveGyroBackgroundModeInNSU:mode];
    return mode;
}

- (void) startGyroUpdates{
    
    if(self.gyroUpdatesStartedByUser) {
        // Inform the error
        if (self.delegate && [self.delegate respondsToSelector:@selector(gyroError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Gyro update in already in progress.",
                                        NSLocalizedFailureReasonErrorKey: @"Gyro update in progress.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try stopping the Gyro updates first."
                                        };
            NSError *error = [NSError errorWithDomain:@"ATGyroMotionManager" code:300 userInfo:userInfo];
            [self.delegate gyroError:error];
            return;
        }
    }
    
    if (!self.motionManager.isGyroAvailable) {
        // Inform the error
        if (self.delegate && [self.delegate respondsToSelector:@selector(gyroError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Gyro not avaliable.",
                                        NSLocalizedFailureReasonErrorKey: @"Gyro not avaliable.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try on device with Gyro"
                                        };
            NSError *error = [NSError errorWithDomain:@"ATGyroMotionManager" code:301 userInfo:userInfo];
            [self.delegate gyroError:error];
        }
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(willStartGyroUpdate)]) {
        [self.delegate willStartGyroUpdate];
    }
    
    // Fetch the values and save them
    self.realTimeCountOfGyroDataPoints = 0;
    self.incomingDataArray = [[NSMutableArray alloc] init];
    self.gyroUpdatesStartedByUser = YES;
    
    NSOperationQueue *opsQueue = [[NSOperationQueue alloc] init];
    opsQueue.name = @"SPTGyro";
    // relatively higher QoS but lower than User interation so they can stop the updates
    opsQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    self.motionManager.gyroUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
    
    // Gyro update handler in a different thread
    [self.motionManager startGyroUpdatesToQueue:opsQueue withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
        if (error || !gyroData || self.gyroUpdatesStoppedByUser ){
            return; // Dont save data after test is stopped
        }
        // Save it in memory array
        @try {
            ATSensorData *data = [[ATSensorData alloc] initWithUpdateX:gyroData.rotationRate.x Y:gyroData.rotationRate.y Z:gyroData.rotationRate.z timeInterval:gyroData.timestamp];
            
            if (data) {
                [self.incomingDataArray addObject:data];
            }
            if (self.incomingDataArray.count > kATIncomingQMaxCount) {
                NSMutableArray *saveArray = self.incomingDataArray;
                self.incomingDataArray = [[NSMutableArray alloc] init];
                [self saveGyroDataToCoreDataFromArray:saveArray];
            }
        } @catch (NSException *exception) {
            NSLog(@"Gyro Exception: %@", exception.debugDescription); // put breakpoint here
        }
        
        // Update delegate that another data has arrived:
        self.realTimeCountOfGyroDataPoints++;
        
        // Protocol - update with test progress
        if (self.delegate && [self.delegate respondsToSelector:@selector(gyroProgressUpdate:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate gyroProgressUpdate:self.realTimeCountOfGyroDataPoints];
            });
        }
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStartGyroUpdate)]) {
        [self.delegate didStartGyroUpdate];
    }
    return;
}

- (void) startGyroUpdatesWithInterval: (NSNumber *) intervalHzWithDouble {
    self.refreshRateHz = [self gyroUpdateInterval:intervalHzWithDouble];
    [self startGyroUpdates];
}

- (void) stopGyroUpdates {
    [self.motionManager stopGyroUpdates]; // Send command anyway
    
    // Check if update was running
    if(!self.gyroUpdatesStartedByUser) {
        // Inform the user of error
        if (self.delegate && [self.delegate respondsToSelector:@selector(gyroError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Gyro update is not progress.",
                                        NSLocalizedFailureReasonErrorKey: @"No Gyro update is in progress.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try starting the Gyro update first."
                                        };
            NSError *error = [NSError errorWithDomain:@"ATGyroMotionManager" code:101 userInfo:userInfo];
            [self.delegate gyroError:error];
            return;
        }
    }
    
    // Control variables.
    self.outgoingDataArray = self.incomingDataArray;
    self.gyroUpdatesStartedByUser = NO;
    self.gyroUpdatesStoppedByUser = YES;
    
    // Protocol - did stop the updates
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStopGyroUpdate)]) {
        [self.delegate didStopGyroUpdate];
    }
    
    [self processResultsInSeparateThread];
}

- (void) processResultsInSeparateThread {
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0ul);
    dispatch_async(queue, ^{
        // Save data in CoreData - thread safe.
        [self saveGyroDataToCoreData];
        
        // Calculate Max and Min sample values
        double maxSampleValue = 0.0, minSampleValue = 0.0;
        for (ATSensorData *d in self.outgoingDataArray) {
            // max of RMS
            double rms = sqrt((d.x * d.x) + (d.y * d.y) + (d.z * d.z));
            if (maxSampleValue < rms) maxSampleValue = rms;
            
            // min of sample values
            if (minSampleValue > d.x) minSampleValue = d.x;
            if (minSampleValue > d.y) minSampleValue = d.y;
            if (minSampleValue > d.z) minSampleValue = d.z;
        }
        NSNumber *maxSampleV = [NSNumber numberWithDouble:maxSampleValue];
        NSNumber *minSampleV = [NSNumber numberWithDouble:minSampleValue];
        
        // Update delegate in main thread. So they can do UX operations
        if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishGyroUpdateWithResults:maxSampleValue:minSampleValue:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.delegate didFinishGyroUpdateWithResults:self.outgoingDataArray maxSampleValue:maxSampleV minSampleValue:minSampleV];
                self.gyroUpdatesStoppedByUser = NO;
            });
        } else {
            self.gyroUpdatesStoppedByUser = NO;
        }
    });
}

- (MFMailComposeViewController *) emailComposerWithGyroData {
    //Get a file name to write the data to using the documents directory:
    NSString *fileName = [ATOUtilities createDataFilePathForName:kATCSVDataFilenameGyro];
    
    // Read contents from CoreData table and store in a NSMutableString
    NSMutableString *coreDataString = [[NSMutableString alloc] init];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"GyroData"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeInterval" ascending:NO]];
    NSError *fetchError;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    [coreDataString appendString:@"x_rad_per_sec,y_rad_per_sec,z_rad_per_sec,rms_rad_per_sec,TimeInterval,Date_approximate\n"];
    
    // Extract the data
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSSSSS Z";
    for (GyroData *d in results) {
        NSString *dateTime = [formatter stringFromDate:d.timestamp];
        NSString *rowData = [NSString stringWithFormat:@"%f,%f,%f,%f,%f,%@\n", d.x.doubleValue, d.y.doubleValue, d.z.doubleValue, d.avgValue.doubleValue, d.timeInterval.doubleValue, dateTime];
        [coreDataString appendString:rowData];
    }
    
    // Save contents to a CSV file.
    [coreDataString writeToFile:fileName  atomically:YES  encoding:NSUTF8StringEncoding error:nil];
    NSData *fileData = [NSData dataWithContentsOfFile:fileName];
    
    // Create the Email message with attachment and compose a viewer
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    [mc setSubject:kATEmailSubjectGyro];
    [mc setMessageBody:kATEmailBodyGyro isHTML:NO];
    [mc addAttachmentData:fileData mimeType:@"text/csv" fileName:kATCSVDataFilenameGyro];
    
    return mc;
}

#pragma mark - Utility methods used in the class
- (void) saveGyroConfigurationInNSU: (NSNumber *) freqHz {
    [[NSUserDefaults standardUserDefaults] setObject:freqHz forKey:@"SPTGyroHzSetting"];
}

- (NSNumber *) getGyroConfigurationInNSU {
    NSNumber *freqHz =  [[NSUserDefaults standardUserDefaults] objectForKey:@"SPTGyroHzSetting"];
    if (!freqHz) {
        freqHz = [[NSNumber alloc] initWithFloat:33.0];
        [self saveGyroConfigurationInNSU:freqHz];
    }
    return freqHz;
}

- (void) saveGyroBackgroundModeInNSU: (BOOL) value {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:kATGyroBackgroundConfigKey];
}

- (BOOL) getGyroBackgroundMode {
    BOOL mode =  [[NSUserDefaults standardUserDefaults] boolForKey:kATGyroBackgroundConfigKey];
    return mode;
}

- (void) trashGyroStoredData {
    // 1. Delete core data
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"GyroData"];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    AppDelegate *app = (AppDelegate *) [UIApplication sharedApplication].delegate;
    NSError *deleteError = nil;
    [app.persistentStoreCoordinator executeRequest:delete withContext:self.managedObjectContext error:&deleteError];
    if (deleteError && self.delegate && [self.delegate respondsToSelector:@selector(gyroError:)]) {
        [self.delegate gyroError:deleteError];
    }
    
    [self.managedObjectContext save:&deleteError];
    if (deleteError && self.delegate && [self.delegate respondsToSelector:@selector(gyroError:)]) {
        [self.delegate gyroError:deleteError];
    }
    
    // 2. Clear .csv file if created for email purposes
    NSString *filePathName = [ATOUtilities createDataFilePathForName:kATCSVDataFilenameGyro];
    [[NSFileManager defaultManager] removeItemAtPath:filePathName error:&deleteError];
    if (deleteError && self.delegate && [self.delegate respondsToSelector:@selector(gyroError:)]) {
        [self.delegate gyroError:deleteError];
    }
    
    // Protocol - completed trashing the data
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTrashGyroDataCache)]) {
        [self.delegate didTrashGyroDataCache];
    }
}

#pragma mark - Core Data Table
- (void) saveGyroDataToCoreData {
    [self saveGyroDataToCoreDataFromArray:self.outgoingDataArray];
}

- (void) saveGyroDataToCoreDataFromArray: (NSMutableArray *) incomingArray {
    [self.managedObjectContext performBlock:^{
        for (ATSensorData *d in incomingArray) {
            GyroData *data = [NSEntityDescription insertNewObjectForEntityForName:@"GyroData" inManagedObjectContext:self.managedObjectContext];
            data.x = [NSNumber numberWithDouble:d.x];
            data.y = [NSNumber numberWithDouble:d.y];
            data.z = [NSNumber numberWithDouble:d.z];
            data.timeInterval = [NSNumber numberWithDouble:d.timestamp]; // Time since last phone bootup.
        }
        
        NSError *error;
        BOOL isSaved = [self.managedObjectContext save:&error];
        if (!isSaved) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(gyroError:)]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate gyroError:error];
                });
            }
        }
    }];
}


@end
