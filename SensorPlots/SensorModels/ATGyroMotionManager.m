//
//  ATGyroMotionManager.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "ATGyroMotionManager.h"
#import "AppDelegate.h"
#import "GyroData.h"
#import "ATOUtilities.h"

@interface ATGyroMotionManager()
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableArray *dataArray; // Values of Gyro are saved here.
@property (strong, nonatomic) AppDelegate *appDelegate;

@property (atomic) BOOL gyroUpdatesInProgress;
@property (atomic) UInt32 realTimeCountOfGyroDataPoints;
@end

@implementation ATGyroMotionManager

#pragma mark - initializers
- (instancetype) init {
    if (self = [super init]) {
        // Configure App delegate, motion manager and MBO
        self.appDelegate = [UIApplication sharedApplication].delegate;
        if ([self.appDelegate respondsToSelector:@selector(motionManager)]) {
            self.motionManager = [self.appDelegate motionManager];
            if (self.motionManager && !self.refreshRateHz ) {
                self.refreshRateHz = [self getGyroConfigurationInNSU];
                self.motionManager.gyroUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
            }
        }
        self.managedObjectContext = self.appDelegate.managedObjectContext;
        self.dataArray = [[NSMutableArray alloc] init];
    }
    if ((!self.motionManager) || (!self.managedObjectContext) || (!self.dataArray) ) {
        return nil; // Initilization failed.
    }
    self.gyroUpdatesInProgress = NO;
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

- (void) startGyroUpdates {
    if (!self.motionManager.isGyroAvailable) {
        // Inform the error
        if (self.delegate && [self.delegate respondsToSelector:@selector(gyroError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Gyro not avaliable.",
                                        NSLocalizedFailureReasonErrorKey: @"Gyro not avaliable.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try on real device"
                                        };
            NSError *error = [NSError errorWithDomain:@"ATGyroMotionManager" code:100 userInfo:userInfo];
            [self.delegate gyroError:error];
        }
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(willStartGyroUpdate)]) {
        [self.delegate willStartGyroUpdate];
    }
    
    if(self.gyroUpdatesInProgress) {
        // Inform the error
        if (self.delegate && [self.delegate respondsToSelector:@selector(gyroError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Gyro update in already in progress.",
                                        NSLocalizedFailureReasonErrorKey: @"Gyro update in progress.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try stopping the Gyro updates first."
                                        };
            NSError *error = [NSError errorWithDomain:@"ATGyroMotionManager" code:101 userInfo:userInfo];
            [self.delegate gyroError:error];
            return;
        }
    }
    
    // Fetch the values and save them
    self.realTimeCountOfGyroDataPoints = 0;
    [self.dataArray removeAllObjects]; // Remove old data
    self.gyroUpdatesInProgress = YES;
    NSOperationQueue *opsQueue = [[NSOperationQueue alloc] init];
    opsQueue.name = @"SPTGyro";
    // relatively higher QoS but lower than User interation so they can stop the updates
    opsQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    self.motionManager.gyroUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
    
    // Gyro update handler
    [self.motionManager startGyroUpdatesToQueue:opsQueue withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
        if (error || !self.gyroUpdatesInProgress){
            return; // Dont save data after test is stopped
        }
        // Save it in memory array
        @try {
            [self.dataArray addObject:gyroData];
        } @catch (NSException *exception) {
            NSLog(@"Exception: %@", exception.debugDescription); // put breakpoint here
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
    // Check if test was running
    if(!self.gyroUpdatesInProgress) {
        // Inform the iser of error
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
    
    // Stop the test.
    self.gyroUpdatesInProgress = NO;
    [self.motionManager stopGyroUpdates];
    
    // Protocol - did stop the test
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStopGyroUpdate)]) {
        [self.delegate didStopGyroUpdate];
    }
    
    // save data to CoreData
    [self saveGyroDataToCoreData];
    
    // Pass on the results
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishGyroUpdateWithResults:)]) {
        [self.delegate didFinishGyroUpdateWithResults:self.dataArray];
    }
}


- (MFMailComposeViewController *) emailComposerWithGyroData {
    //Get a file name to write the data to using the documents directory:
    NSString *fileName = [ATOUtilities createDataFilePathForName:@"Gyro.csv"];
    
    // Read contents from CoreData table and store in a NSMutableString
    NSMutableString *coreDataString = [[NSMutableString alloc] init];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"GyroData"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeInterval" ascending:NO]];
    NSError *fetchError;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    [coreDataString appendString:@"x_rad_per_sec,y_rad_per_sec,z_rad_per_sec,rms_rad_per_sec,TimeInterval,Date\n"];
    
    // Extract the data
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS Z";
    for (GyroData *d in results) {
        NSString *dateTime = [formatter stringFromDate:d.timestamp];
        NSString *rowData = [NSString stringWithFormat:@"%f,%f,%f,%f,%f,%@\n", d.x.doubleValue, d.y.doubleValue, d.z.doubleValue, d.avgValue.doubleValue, d.timeInterval.doubleValue, dateTime];
        [coreDataString appendString:rowData];
    }
    
    // Save contents to a CSV file.
    [coreDataString writeToFile:fileName  atomically:YES  encoding:NSUTF8StringEncoding error:nil];
    NSData *fileData = [NSData dataWithContentsOfFile:fileName];
    
    // Create the Email message with attachment and compose a viewer
    NSString *emailTitle = @"PlutoApps: Your Gyro test data"; // Email Subject
    // Email Content
    NSString *messageBody = @"Your data is in attached file Gyro.csv. The units are in radians per second."
            " The data are sorted by timestamp in decending order."
            " If you have questions email me at plutoapps@outlook.com\n";
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc addAttachmentData:fileData mimeType:@"text/csv" fileName:@"Gyro.csv"];
    
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

- (void) trashGyroStoredData {
    
    // 1. Delete core data
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"GyroData"];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    AppDelegate *app = [UIApplication sharedApplication].delegate;
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
    NSString *filePathName = [ATOUtilities createDataFilePathForName:@"Gyro.csv"];
    [[NSFileManager defaultManager] removeItemAtPath:filePathName error:&deleteError];
    if (deleteError && self.delegate && [self.delegate respondsToSelector:@selector(gyroError:)]) {
        [self.delegate gyroError:deleteError];
    }
    
    // 3. Clear Memory
    [self.dataArray removeAllObjects];
    
    // Protocol - completed trashing the data
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTrashGyroDataCache)]) {
        [self.delegate didTrashGyroDataCache];
    }
}

#pragma mark - Core Data Table
- (void) saveGyroDataToCoreData {
    
    for (CMGyroData *d in self.dataArray) {
        GyroData *data = [NSEntityDescription insertNewObjectForEntityForName:@"GyroData" inManagedObjectContext:self.managedObjectContext];
        data.x = [NSNumber numberWithDouble:d.rotationRate.x];
        data.y = [NSNumber numberWithDouble:d.rotationRate.y];
        data.z = [NSNumber numberWithDouble:d.rotationRate.z];
        data.timeInterval = [NSNumber numberWithDouble:d.timestamp]; // Time since last phone bootup.
    }
    
    NSError *error;
    BOOL isSaved = [self.managedObjectContext save:&error];
    if (!isSaved) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(gyroError:)]) {
            [self.delegate gyroError:error];
        }
    }
}

@end
