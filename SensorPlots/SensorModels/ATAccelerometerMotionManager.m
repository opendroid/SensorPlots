//
//  ATSMotionAccelerometerManager.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/3/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "ATAccelerometerMotionManager.h"
#import "AppDelegate.h"
#import "AccelerometerData+CoreDataClass.h"
#import "ATOUtilities.h"
#import "ATSensorData.h"
#import "SPTConstants.h"

@interface ATAccelerometerMotionManager()

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableArray *incomingDataArray; // Incoming data from IOS
@property (strong, nonatomic) NSMutableArray *outgoingDataArray; // Data sent to View Controller
@property (strong, nonatomic) AppDelegate *appDelegate;

@property (atomic) BOOL accelerometerStartedByUser;
@property (atomic) __block BOOL accelerometerStoppedByUser; // Checked in block.
@property (atomic) UInt32 realTimeCountOfAcclerometerDataPoints;
@property (atomic) UInt64 acceleroTestID; // Save the Test ID for this test
@property (atomic) UInt64 acceleroTestSampleID; // Save the Sample ID
@end

@implementation ATAccelerometerMotionManager

#pragma mark - initializers
- (instancetype) init {
    if (self = [super init]) {
        // Configure App delegate, motion manager and MBO
        self.appDelegate =(AppDelegate *) [UIApplication sharedApplication].delegate;
        if ([self.appDelegate respondsToSelector:@selector(motionManager)]) {
            self.motionManager = [self.appDelegate motionManager];
            if (self.motionManager && !self.refreshRateHz ) {
                self.refreshRateHz = [self getAccelerometerConfigurationInNSU];
                self.motionManager.accelerometerUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
            }
        }
        self.managedObjectContext = self.appDelegate.managedObjectContext;
    }
    if ((!self.motionManager) || (!self.managedObjectContext)) {
        return nil; // Initilization failed.
    }
    self.accelerometerStartedByUser = NO;
    self.accelerometerStoppedByUser = NO;
    return self;
}

- (instancetype) initWithUpdateInterval: (NSNumber *) updateInterval {
    if (self = [self init]) {
        self.refreshRateHz = [self accelerometerUpdateInterval:updateInterval];
    }
    
    return self;
}

#pragma mark - Public accesors
- (NSNumber *) savedCountOfAcclerometerDataPoints {
    // Check if there is data in 'AccelerometerData' to send.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"AccelerometerData"];
    fetchRequest.resultType = NSCountResultType;
    NSError *fetchError = nil;
    NSUInteger itemsCount = [self.managedObjectContext countForFetchRequest:fetchRequest error:&fetchError];
    if (itemsCount == NSNotFound) {
        itemsCount = 0;
    }
    NSNumber *item = [NSNumber numberWithInteger:itemsCount];
    return item;
}

- (NSNumber *) accelerometerUpdateInterval: (NSNumber *) intervalHzWithDouble {
    
    if (intervalHzWithDouble.doubleValue < 1.0) {
        self.refreshRateHz = [NSNumber numberWithDouble:1.0];
    } else if ( intervalHzWithDouble.doubleValue > 100.00) {
        self.refreshRateHz = [NSNumber numberWithDouble:100.0];
    } else {
        self.refreshRateHz = intervalHzWithDouble;
    }
    self.motionManager.accelerometerUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
    [self saveAccelerometerConfigurationInNSU:self.refreshRateHz];
    return self.refreshRateHz;
}

- (BOOL) accelerometerUpdateBackgroundMode: (BOOL) mode {
    [self saveAccelerometerBackgroundModeInNSU:mode];
    return mode;
}
- (void) startAccelerometerUpdates {
    
    if(self.accelerometerStartedByUser) {
        // Inform the error
        if (self.delegate && [self.delegate respondsToSelector:@selector(accelerometerError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Accelero updates in progress.",
                                        NSLocalizedFailureReasonErrorKey: @"Error starting update.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try stopping the updates first."
                                        };
            NSError *error = [NSError errorWithDomain:@"ATAccelerometerMotionManager" code:100 userInfo:userInfo];
            [self.delegate accelerometerError:error];
            return;
        }
    }
    
    if (!self.motionManager.isAccelerometerAvailable) {
        // Inform the error
        if (self.delegate && [self.delegate respondsToSelector:@selector(accelerometerError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Accelerometer not avaliable.",
                                        NSLocalizedFailureReasonErrorKey: @"Accelerometer not avaliable.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try on device that has accelerometer"
                                        };
            NSError *error = [NSError errorWithDomain:@"ATAccelerometerMotionManager" code:101 userInfo:userInfo];
            [self.delegate accelerometerError:error];
        }
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(willStartAccelerometerUpdate)]) {
        [self.delegate willStartAccelerometerUpdate];
    }
    
    // Fetch the values and save them
    self.realTimeCountOfAcclerometerDataPoints = 0;
    self.incomingDataArray = [[NSMutableArray alloc] init];
    self.acceleroTestSampleID = 0;
    self.accelerometerStartedByUser = YES;
    
    NSOperationQueue *opsQueue = [[NSOperationQueue alloc] init];
    opsQueue.name = @"SPTAccelerator";
    // relatively higher QoS but lower than User interation so they can stop the updates
    opsQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    self.motionManager.accelerometerUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
    
    // Start the updates in a different thread
    [self.motionManager startAccelerometerUpdatesToQueue:opsQueue withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        if (error || !accelerometerData || self.accelerometerStoppedByUser){
            return; // Dont save data until last stop has taken into affect
        }
        // Save it in memory array
        @try {
            ATSensorData *data = [[ATSensorData alloc] initWithUpdateX:accelerometerData.acceleration.x Y:accelerometerData.acceleration.y Z:accelerometerData.acceleration.z timeInterval:accelerometerData.timestamp];
            if (data) {
                [self.incomingDataArray addObject:data];
            }
            if (self.incomingDataArray.count > kATIncomingQMaxCount) {
                NSMutableArray *saveArray = self.incomingDataArray;
                self.incomingDataArray = [[NSMutableArray alloc] init];
                [self saveAccelerometerDataToCoreDataFromArray:saveArray];
            }
        } @catch (NSException *exception) {
            NSLog(@"Accelerometer Exception: %@", exception.debugDescription); // put breakpoint here
        }
        
        // Update delegate that another data has arrived:
        self.realTimeCountOfAcclerometerDataPoints++;
        
        // Protocol - update with test progress
        if (self.delegate && [self.delegate respondsToSelector:@selector(accelerometerProgressUpdate:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate accelerometerProgressUpdate:self.realTimeCountOfAcclerometerDataPoints];
            });
        }
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStartAccelerometerUpdate)]) {
        [self.delegate didStartAccelerometerUpdate];
    }
    return;
}

- (void) startAccelerometerUpdatesWithInterval: (NSNumber *) intervalHzWithDouble {
    self.refreshRateHz = [self accelerometerUpdateInterval:intervalHzWithDouble];
    [self startAccelerometerUpdates];
}

- (void) stopAccelerometerUpdates {
    [self.motionManager stopAccelerometerUpdates];
    
    // Check if test was running
    if(!self.accelerometerStartedByUser) {
        // Inform the iser of error
        if (self.delegate && [self.delegate respondsToSelector:@selector(accelerometerError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Test is not progress.",
                                        NSLocalizedFailureReasonErrorKey: @"No test is in progress.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try starting the test first."
                                        };
            NSError *error = [NSError errorWithDomain:@"ATAccelerometerMotionManager" code:101 userInfo:userInfo];
            [self.delegate accelerometerError:error];
            return;
        }
    }
    
    // Stop the test.
    self.outgoingDataArray = self.incomingDataArray;
    self.accelerometerStartedByUser = NO;
    self.accelerometerStoppedByUser = YES;
    
    // Protocol - did stop the test
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStopAccelerometerUpdate)]) {
        [self.delegate didStopAccelerometerUpdate];
    }
    
    [self processResultsInSeparateThread];
}

- (void) processResultsInSeparateThread {
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0ul);
    dispatch_async(queue, ^{
        // Save data in CoreData - thread safe.
        [self saveAccelerometerDataToCoreData];
        
        // Calculate Max and Min Y
        double maxSampleValue = 0.0, minSampleValue = 0.0;
        for (ATSensorData *d in self.outgoingDataArray) {
            double rms = sqrt((d.x * d.x) + (d.y * d.y) + (d.z * d.z));
            if (maxSampleValue < rms) maxSampleValue = rms;
            if (minSampleValue > d.x) minSampleValue = d.x;
            if (minSampleValue > d.y) minSampleValue = d.y;
            if (minSampleValue > d.z) minSampleValue = d.z;
        }
        
        NSNumber *maxSampleV = [NSNumber numberWithDouble:maxSampleValue];
        NSNumber *minSampleV = [NSNumber numberWithDouble:minSampleValue];
        
        // Update delegate in main thread. So they can do UX operations
        if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishAccelerometerUpdateWithResults:maxSampleValue:minSampleValue:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.delegate didFinishAccelerometerUpdateWithResults:self.outgoingDataArray maxSampleValue:maxSampleV minSampleValue:minSampleV];
                self.accelerometerStoppedByUser = NO;
            });
        } else {
            self.accelerometerStoppedByUser = NO;
        }
    });
}

- (MFMailComposeViewController *) emailComposerWithAccelerometerData {
    //Get a file name to write the data to using the documents directory:
    NSString *fileName = [ATOUtilities createDataFilePathForName:kATCSVDataFilenameAccelero];
    
    // Read contents from CoreData table and store in a NSMutableString
    NSMutableString *coreDataString = [[NSMutableString alloc] init];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"AccelerometerData"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeInterval" ascending:NO]];
    NSError *fetchError;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    [coreDataString appendString:@"x_times_g,y_times_g,z_times_g,g_measured,TimeInterval,Date_approximate\n"];
    
    // Extract the data
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSSSSS Z";
    for (AccelerometerData *d in results) {
        NSString *dateTime = [formatter stringFromDate:d.timestamp];
        NSString *rowData = [NSString stringWithFormat:@"%f,%f,%f,%f,%f,%@\n", d.x.doubleValue, d.y.doubleValue, d.z.doubleValue, d.avgValue.doubleValue, d.timeInterval.doubleValue, dateTime];
        [coreDataString appendString:rowData];
    }
    
    // Save contents to a CSV file.
    [coreDataString writeToFile:fileName  atomically:YES  encoding:NSUTF8StringEncoding error:nil];
    NSData *fileData = [NSData dataWithContentsOfFile:fileName];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    [mc setSubject:kATEmailSubjectAccelero];
    [mc setMessageBody:kATEmailBodyAccelero isHTML:NO];
    [mc addAttachmentData:fileData mimeType:@"text/csv" fileName:kATCSVDataFilenameAccelero];
    
    return mc;
}

#pragma mark - Utility methods used in the class
- (void) saveAccelerometerConfigurationInNSU: (NSNumber *) freqHz {
    [[NSUserDefaults standardUserDefaults] setObject:freqHz forKey:kATAcceleroSampleRateHzKey];
}

- (NSNumber *) getAccelerometerConfigurationInNSU {
    NSNumber *freqHz =  [[NSUserDefaults standardUserDefaults] objectForKey:kATAcceleroSampleRateHzKey];
    if (!freqHz) {
        freqHz = [[NSNumber alloc] initWithFloat:33.0];
        [self saveAccelerometerConfigurationInNSU:freqHz];
    }
    return freqHz;
}

- (void) saveAccelerometerBackgroundModeInNSU: (BOOL) value {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:kATAcceleroBackgroundConfigKey];
}

- (BOOL) getAccelerometerBackgroundMode {
    BOOL mode =  [[NSUserDefaults standardUserDefaults] boolForKey:kATAcceleroBackgroundConfigKey];
    return mode;
}

- (void) trashAccelerometerStoredData {
    // 1. Delete core data
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"AccelerometerData"];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    AppDelegate *app = (AppDelegate *) [UIApplication sharedApplication].delegate;
    NSError *deleteError = nil;
    [app.persistentStoreCoordinator executeRequest:delete withContext:self.managedObjectContext error:&deleteError];
    if (deleteError && self.delegate && [self.delegate respondsToSelector:@selector(accelerometerError:)]) {
        [self.delegate accelerometerError:deleteError];
    }

    [self.managedObjectContext save:&deleteError];
    if (deleteError && self.delegate && [self.delegate respondsToSelector:@selector(accelerometerError:)]) {
        [self.delegate accelerometerError:deleteError];
    }

    // 2. Clear .csv file if created for email purposes
    NSString *fileNameWithPath = [ATOUtilities createDataFilePathForName:kATCSVDataFilenameAccelero];
    [[NSFileManager defaultManager] removeItemAtPath:fileNameWithPath error:&deleteError];
    if (deleteError && self.delegate && [self.delegate respondsToSelector:@selector(accelerometerError:)]) {
        [self.delegate accelerometerError:deleteError];
    }
    
    // Protocol - completed trashing the data
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTrashAccelerometerDataCache)]) {
        [self.delegate didTrashAccelerometerDataCache];
    }
}

#pragma mark - Core Data Table
- (void) saveAccelerometerDataToCoreData {
    
    [self saveAccelerometerDataToCoreDataFromArray:self.outgoingDataArray];
}

- (void) saveAccelerometerDataToCoreDataFromArray: (NSMutableArray *) incomingArray {
    
    [self.managedObjectContext performBlock:^{
        for (ATSensorData *d in incomingArray) {
            AccelerometerData *data = [NSEntityDescription insertNewObjectForEntityForName:@"AccelerometerData" inManagedObjectContext:self.managedObjectContext];
            self.acceleroTestSampleID++;
            data.x = [NSNumber numberWithDouble:d.x];
            data.y = [NSNumber numberWithDouble:d.y];
            data.z = [NSNumber numberWithDouble:d.z];
            data.timeInterval = [NSNumber numberWithDouble:d.timestamp]; // Time since last phone bootup.
            data.sampleID = [NSNumber numberWithLongLong:self.acceleroTestSampleID];
            data.testID = [NSNumber numberWithLongLong:self.acceleroTestID];
        }
        __block NSError *error;
        BOOL isSaved = [self.managedObjectContext save:&error];
        if (!isSaved) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(accelerometerError:)]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate accelerometerError:error];
                });
            }
        }
    }];
}

@end
