//
//  ATMagnetoMotionManager.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "ATMagnetoMotionManager.h"
#import "AppDelegate.h"
#import "MagnetoData.h"
#import "ATOUtilities.h"
#import "ATSensorData.h"
#import "SPTConstants.h"

@interface ATMagnetoMotionManager()

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableArray *incomingDataArray; // Incoming data from IOS
@property (strong, nonatomic) NSMutableArray *outgoingDataArray; // Data sent to View Controller
@property (strong, nonatomic) AppDelegate *appDelegate;

@property (atomic) BOOL magnetoUpdatesStartedByUser;
@property (atomic) __block BOOL magnetoUpdatesStoppedByUser; // Checked in block.
@property (atomic) UInt32 realTimeCountOfMagnetoDataPoints;
@end

@implementation ATMagnetoMotionManager

#pragma mark - initializers
- (instancetype) init {
    if (self = [super init]) {
        // Configure App delegate, motion manager and MBO
        self.appDelegate = [UIApplication sharedApplication].delegate;
        if ([self.appDelegate respondsToSelector:@selector(motionManager)]) {
            self.motionManager = [self.appDelegate motionManager];
            if (self.motionManager && !self.refreshRateHz ) {
                self.refreshRateHz = [self getMagnetoConfigurationInNSU];
                self.motionManager.magnetometerUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
            }
        }
        self.managedObjectContext = self.appDelegate.managedObjectContext;
    }
    if ((!self.motionManager) || (!self.managedObjectContext)) {
        return nil; // Initilization failed.
    }
    self.magnetoUpdatesStartedByUser = NO;
    self.magnetoUpdatesStoppedByUser = NO;
    return self;
}

- (instancetype) initWithUpdateInterval: (NSNumber *) updateInterval {
    if (self = [self init]) {
        self.refreshRateHz = [self magnetoUpdateInterval:updateInterval];
    }
    
    return self;
}

#pragma mark - Public accesors
- (NSNumber *) savedCountOfMagnetoDataPoints {
    // Check if there is data in 'MagnetoData' to send.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MagnetoData"];
    fetchRequest.resultType = NSCountResultType;
    NSError *fetchError = nil;
    NSUInteger itemsCount = [self.managedObjectContext countForFetchRequest:fetchRequest error:&fetchError];
    if (itemsCount == NSNotFound) {
        itemsCount = 0;
    }
    NSNumber *item = [NSNumber numberWithInteger:itemsCount];
    return item;
}

- (NSNumber *) magnetoUpdateInterval: (NSNumber *) intervalHzWithDouble {
    
    if (intervalHzWithDouble.doubleValue < 1.0) {
        self.refreshRateHz = [NSNumber numberWithDouble:1.0];
    } else if ( intervalHzWithDouble.doubleValue > 100.00) {
        self.refreshRateHz = [NSNumber numberWithDouble:100.0];
    } else {
        self.refreshRateHz = intervalHzWithDouble;
    }
    self.motionManager.magnetometerUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
    [self saveMagnetoConfigurationInNSU:self.refreshRateHz];
    return self.refreshRateHz;
}

- (void) startMagnetoUpdates {
    if (!self.motionManager.isMagnetometerAvailable) {
        // Inform the error
        if (self.delegate && [self.delegate respondsToSelector:@selector(magnetoError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Magnetometer not avaliable.",
                                        NSLocalizedFailureReasonErrorKey: @"Magnetometer not avaliable.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try on real device"
                                        };
            NSError *error = [NSError errorWithDomain:@"ATMagnetoMotionManager" code:300 userInfo:userInfo];
            [self.delegate magnetoError:error];
        }
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(willStartMagnetoUpdate)]) {
        [self.delegate willStartMagnetoUpdate];
    }
    
    if(self.magnetoUpdatesStartedByUser) {
        // Inform the error
        if (self.delegate && [self.delegate respondsToSelector:@selector(magnetoError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Magneto updates already in progress.",
                                        NSLocalizedFailureReasonErrorKey: @"Magnetometer updates in progress.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Stopping the Magnetometer."
                                        };
            NSError *error = [NSError errorWithDomain:@"ATMagnetoMotionManager" code:301 userInfo:userInfo];
            [self.delegate magnetoError:error];
            return;
        }
    }
    
    // Fetch the values and save them
    self.realTimeCountOfMagnetoDataPoints = 0;
    self.incomingDataArray = [[NSMutableArray alloc] init];
    self.magnetoUpdatesStartedByUser = YES;
    NSOperationQueue *opsQueue = [[NSOperationQueue alloc] init];
    opsQueue.name = @"SPTMagneto";
    // relatively higher QoS but lower than User interation so they can stop the updates
    opsQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    self.motionManager.magnetometerUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
    [self.motionManager startMagnetometerUpdatesToQueue:opsQueue withHandler:^(CMMagnetometerData * _Nullable magnetoData, NSError * _Nullable error) {
        if (error || !magnetoData || self.magnetoUpdatesStoppedByUser){
            return; // Dont save data after test is stopped
        }
        // Save it in memory array
        @try {
            ATSensorData *data = [[ATSensorData alloc] initWithUpdateX:magnetoData.magneticField.x Y:magnetoData.magneticField.y Z:magnetoData.magneticField.z timeInterval:magnetoData.timestamp];
            
            if (data) {
                [self.incomingDataArray addObject:data];
            }
            if (self.incomingDataArray.count > kATIncomingQMaxCount) {
                NSMutableArray *saveArray = self.incomingDataArray;
                self.incomingDataArray = [[NSMutableArray alloc] init];
                [self saveMagnetoDataToCoreDataFromArray:saveArray];
            }
        } @catch (NSException *exception) {
            NSLog(@"Gyro Exception: %@", exception.debugDescription); // put breakpoint here
        }
        
        // Update delegate that another data has arrived:
        self.realTimeCountOfMagnetoDataPoints++;
        // Protocol - update with test progress
        if (self.delegate && [self.delegate respondsToSelector:@selector(magnetoProgressUpdate:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate magnetoProgressUpdate:self.realTimeCountOfMagnetoDataPoints];
            });
        }
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStartMagnetoUpdate)]) {
        [self.delegate didStartMagnetoUpdate];
    }
    return;
}


- (void) startMagnetoUpdatesWithInterval: (NSNumber *) intervalHzWithDouble {
    self.refreshRateHz = [self magnetoUpdateInterval:intervalHzWithDouble];
    [self startMagnetoUpdates];
}

- (void) stopMagnetoUpdates {
    [self.motionManager stopMagnetometerUpdates];
    
    // Check if test was running
    if(!self.magnetoUpdatesStartedByUser) {
        // Inform the iser of error
        if (self.delegate && [self.delegate respondsToSelector:@selector(magnetoError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Magnetometer update is not progress.",
                                        NSLocalizedFailureReasonErrorKey: @"Magnetometer update is in progress.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try starting the magentometer first."
                                        };
            NSError *error = [NSError errorWithDomain:@"ATMagnetoMotionManager" code:101 userInfo:userInfo];
            [self.delegate magnetoError:error];
            return;
        }
    }
    
    // Control variables.
    self.outgoingDataArray = self.incomingDataArray;
    self.magnetoUpdatesStartedByUser = NO;
    self.magnetoUpdatesStoppedByUser = YES;

    
    // Protocol - did stop the test
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStopMagnetoUpdate)]) {
        [self.delegate didStopMagnetoUpdate];
    }
    
    [self processResultsInSeparateThread];
}

- (void) processResultsInSeparateThread {
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0ul);
    dispatch_async(queue, ^{
        // Save data in CoreData - thread safe.
        [self saveMagnetoDataToCoreData];
        
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
        if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishMagnetoUpdateWithResults:maxSampleValue:minSampleValue:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.delegate didFinishMagnetoUpdateWithResults:self.outgoingDataArray maxSampleValue:maxSampleV minSampleValue:minSampleV];
                self.magnetoUpdatesStoppedByUser = NO;
            });
        } else {
            self.magnetoUpdatesStoppedByUser = NO;
        }
    });
}

- (MFMailComposeViewController *) emailComposerWithMagnetoData {
    //Get a file name to write the data to using the documents directory:
    NSString *fileName = [ATOUtilities createDataFilePathForName:kATCSVDataFilenameMagneto];
    
    // Read contents from CoreData table and store in a NSMutableString
    NSMutableString *coreDataString = [[NSMutableString alloc] init];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MagnetoData"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeInterval" ascending:NO]];
    NSError *fetchError;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    [coreDataString appendString:@"x_micro_tesla,y_micro_tesla,z_micro_tesla,rms_micro_tesla,TimeInterval,Date_approximate\n"];
    
    // Extract the data
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSSSSS Z";
    for (MagnetoData *d in results) {
        NSString *dateTime = [formatter stringFromDate:d.timestamp];
        NSString *rowData = [NSString stringWithFormat:@"%f,%f,%f,%f,%f,%@\n", d.x.doubleValue, d.y.doubleValue, d.z.doubleValue, d.avgValue.doubleValue, d.timeInterval.doubleValue, dateTime];
        [coreDataString appendString:rowData];
    }
    
    // Save contents to a CSV file.
    [coreDataString writeToFile:fileName  atomically:YES  encoding:NSUTF8StringEncoding error:nil];
    NSData *fileData = [NSData dataWithContentsOfFile:fileName];
    
    // Create the Email message with attachment and compose a viewer
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    [mc setSubject:kATEmailSubjectMagneto];
    [mc setMessageBody:kATEmailBodyMagneto isHTML:NO];
    [mc addAttachmentData:fileData mimeType:@"text/csv" fileName:kATCSVDataFilenameMagneto];
    
    return mc;
}

#pragma mark - Utility methods used in the class
- (void) saveMagnetoConfigurationInNSU: (NSNumber *) freqHz {
    [[NSUserDefaults standardUserDefaults] setObject:freqHz forKey:@"SPTMagnetoHzSetting"];
}

- (NSNumber *) getMagnetoConfigurationInNSU {
    NSNumber *freqHz =  [[NSUserDefaults standardUserDefaults] objectForKey:@"SPTMagnetoHzSetting"];
    if (!freqHz) {
        freqHz = [[NSNumber alloc] initWithFloat:33.0];
        [self saveMagnetoConfigurationInNSU:freqHz];
    }
    return freqHz;
}

- (void) trashMagnetoStoredData {
    
    // 1. Delete core data
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"MagnetoData"];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    AppDelegate *app = [UIApplication sharedApplication].delegate;
    NSError *deleteError = nil;
    [app.persistentStoreCoordinator executeRequest:delete withContext:self.managedObjectContext error:&deleteError];
    if (deleteError && self.delegate && [self.delegate respondsToSelector:@selector(magnetoError:)]) {
        [self.delegate magnetoError:deleteError];
    }
    
    [self.managedObjectContext save:&deleteError];
    if (deleteError && self.delegate && [self.delegate respondsToSelector:@selector(magnetoError:)]) {
        [self.delegate magnetoError:deleteError];
    }
    
    // 2. Clear .csv file if created for email purposes
    NSString *filePathName = [ATOUtilities createDataFilePathForName:kATCSVDataFilenameMagneto];
    [[NSFileManager defaultManager] removeItemAtPath:filePathName error:&deleteError];
    if (deleteError && self.delegate && [self.delegate respondsToSelector:@selector(magnetoError:)]) {
        [self.delegate magnetoError:deleteError];
    }
    
    // Protocol - completed trashing the data
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTrashMagnetoDataCache)]) {
        [self.delegate didTrashMagnetoDataCache];
    }
}

#pragma mark - Core Data Table
- (void) saveMagnetoDataToCoreData {
    [self saveMagnetoDataToCoreDataFromArray:self.outgoingDataArray];
}

- (void) saveMagnetoDataToCoreDataFromArray: (NSMutableArray *) incomingArray {
    [self.managedObjectContext performBlock:^{
        for (ATSensorData *d in incomingArray) {
            MagnetoData *data = [NSEntityDescription insertNewObjectForEntityForName:@"MagnetoData" inManagedObjectContext:self.managedObjectContext];
            data.x = [NSNumber numberWithDouble:d.x];
            data.y = [NSNumber numberWithDouble:d.y];
            data.z = [NSNumber numberWithDouble:d.z];
            data.timeInterval = [NSNumber numberWithDouble:d.timestamp]; // Time since last phone bootup.
        }
        
        __block NSError *error;
        BOOL isSaved = [self.managedObjectContext save:&error];
        if (!isSaved) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(magnetoError:)]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate magnetoError:error];
                });
            }
        }
    }];
}


@end
