//
//  ATSMotionAccelerometerManager.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/3/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "ATSMotionAccelerometerManager.h"
#import "AppDelegate.h"
#import "AccelerometerData.h"

@interface ATSMotionAccelerometerManager()

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableArray *dataArray; // Values of accelerometer are saved here.
@property (strong, nonatomic) AppDelegate *appDelegate;

@property (atomic) BOOL testInProgress;
@property (atomic) UInt32 realTimeCountOfAcclerometerDataPoints;

@end

@implementation ATSMotionAccelerometerManager

#pragma mark - initializers
- (instancetype) init {
    if (self = [super init]) {
        // Configure App delegate, motion manager and MBO
        self.appDelegate = [UIApplication sharedApplication].delegate;
        if ([self.appDelegate respondsToSelector:@selector(motionManager)]) {
            self.motionManager = [self.appDelegate motionManager];
            if (self.motionManager && !self.refreshRateHz ) {
                self.refreshRateHz = [self getAccelerometerConfigurationInNSU];
                self.motionManager.accelerometerUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
            }
        }
        self.managedObjectContext = self.appDelegate.managedObjectContext;
        self.dataArray = [[NSMutableArray alloc] init];
    }
    if ((!self.motionManager) || (!self.managedObjectContext) || (!self.dataArray) ) {
        return nil; // Initilization failed.
    }
    self.testInProgress = NO;
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

- (void) startAccelerometerUpdates {
    if (!self.motionManager.isAccelerometerAvailable) {
        // Inform the error
        if (self.delegate && [self.delegate respondsToSelector:@selector(accelerometerError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Accelerometer not avaliable.",
                                        NSLocalizedFailureReasonErrorKey: @"Accelerometer not avaliable.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try on real device"
                                        };
            NSError *error = [NSError errorWithDomain:@"ATSMotionAccelerometerManager" code:100 userInfo:userInfo];
            [self.delegate accelerometerError:error];
        }
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(willStartAccelerometerUpdate)]) {
        [self.delegate willStartAccelerometerUpdate];
    }
    
    if(self.testInProgress) {
        // Inform the error
        if (self.delegate && [self.delegate respondsToSelector:@selector(accelerometerError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Test in already in progress.",
                                        NSLocalizedFailureReasonErrorKey: @"Test in progress.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try stopping the test."
                                        };
            NSError *error = [NSError errorWithDomain:@"ATSMotionAccelerometerManager" code:101 userInfo:userInfo];
            [self.delegate accelerometerError:error];
            return;
        }
    }
    
    // Fetch the values and save them
    self.realTimeCountOfAcclerometerDataPoints = 0;
    [self.dataArray removeAllObjects]; // Remove old data
    self.testInProgress = YES;
    NSOperationQueue *opsQueue = [[NSOperationQueue alloc] init];
    opsQueue.name = @"SPTAccelerator";
    // relatively higher QoS but lower than User interation so they can stop the updates
    opsQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    self.motionManager.accelerometerUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
    [self.motionManager startAccelerometerUpdatesToQueue:opsQueue withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        if (!self.testInProgress){
            return; // Dont save data after test is stopped
        }
        // Save it in memory array
        [self.dataArray addObject:accelerometerData];
        
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
    // Check if test was running
    if(!self.testInProgress) {
        // Inform the iser of error
        if (self.delegate && [self.delegate respondsToSelector:@selector(accelerometerError:)]) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey:@"Test is not progress.",
                                        NSLocalizedFailureReasonErrorKey: @"No test is in progress.",
                                        NSLocalizedRecoveryOptionsErrorKey:@"Try starting the test first."
                                        };
            NSError *error = [NSError errorWithDomain:@"ATSMotionAccelerometerManager" code:101 userInfo:userInfo];
            [self.delegate accelerometerError:error];
            return;
        }
    }
    
    // Stop the test.
    self.testInProgress = NO;
    [self.motionManager stopAccelerometerUpdates];
    
    // Protocol - did stop the test
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStopAccelerometerUpdate)]) {
        [self.delegate didStopAccelerometerUpdate];
    }

    // save data to CoreData
    [self saveAccelerometerDataToCoreData];
    
    // Pass on the results
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishAccelerometerTestWithResults:)]) {
        [self.delegate didFinishAccelerometerTestWithResults:self.dataArray];
    }
}


- (MFMailComposeViewController *) emailComposerWithTestData {
    //Get a file name to write the data to using the documents directory:
    NSString *fileName = [self createFilePath];
    
    // Read contents from CoreData table and store in a NSMutableString
    NSMutableString *coreDataString = [[NSMutableString alloc] init];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"AccelerometerData"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeinterval" ascending:NO]];
    NSError *fetchError;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    [coreDataString appendString:@"x,y,z,g,TimeInterval,Date\n"];
    
    // Extract the data
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS Z";
    for (AccelerometerData *d in results) {
        NSString *dateTime = [formatter stringFromDate:d.timestamp];
        NSString *rowData = [NSString stringWithFormat:@"%f,%f,%f,%f,%f,%@\n", d.x.doubleValue, d.y.doubleValue, d.z.doubleValue, d.gValue.doubleValue, d.timeinterval.doubleValue, dateTime];
        [coreDataString appendString:rowData];
    }
    
    // Save contents to a CSV file.
    [coreDataString writeToFile:fileName  atomically:YES  encoding:NSUTF8StringEncoding error:nil];
    NSData *fileData = [NSData dataWithContentsOfFile:fileName];
    
    // Create the Email message with attachment and compose a viewer
    NSString *emailTitle = @"PlutoApps: Your accelerometer test data"; // Email Subject
    NSString *messageBody = @"Data is attached in file accelerometer.csv\n"; // Email Content
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc addAttachmentData:fileData mimeType:@"text/csv" fileName:@"accelerometer.csv"];
    
    return mc;
}

#pragma mark - Utility methods used in the class
- (void) saveAccelerometerConfigurationInNSU: (NSNumber *) freqHz {
    [[NSUserDefaults standardUserDefaults] setObject:freqHz forKey:@"SPTAccelerometerHzSetting"];
}

- (NSNumber *) getAccelerometerConfigurationInNSU {
    NSNumber *freqHz =  [[NSUserDefaults standardUserDefaults] objectForKey:@"SPTAccelerometerHzSetting"];
    if (!freqHz) {
        freqHz = [[NSNumber alloc] initWithFloat:33.0];
        [self saveAccelerometerConfigurationInNSU:freqHz];
    }
    return freqHz;
}

- (void) trashAccelerometerStoredData {
    
    // 1. Delete core data
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"AccelerometerData"];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    AppDelegate *app = [UIApplication sharedApplication].delegate;
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
    [[NSFileManager defaultManager] removeItemAtPath:self.createFilePath error:&deleteError];
    if (deleteError && self.delegate && [self.delegate respondsToSelector:@selector(accelerometerError:)]) {
        [self.delegate accelerometerError:deleteError];
    }
    
    // 3. Clear Memory
    [self.dataArray removeAllObjects];
    
    // Protocol - completed trashing the data
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTrashAccelerometerDataCache)]) {
        [self.delegate didTrashAccelerometerDataCache];
    }
}

#pragma mark - Core Data Table
- (void) saveAccelerometerDataToCoreData {
    
    for (CMAccelerometerData *d in self.dataArray) {
        AccelerometerData *data = [NSEntityDescription insertNewObjectForEntityForName:@"AccelerometerData" inManagedObjectContext:self.managedObjectContext];
        data.x = [NSNumber numberWithDouble:d.acceleration.x];
        data.y = [NSNumber numberWithDouble:d.acceleration.y];
        data.z = [NSNumber numberWithDouble:d.acceleration.z];
        data.timeinterval = [NSNumber numberWithDouble:d.timestamp]; // Time since last phone bootup.
    }
    
    NSError *error;
    BOOL isSaved = [self.managedObjectContext save:&error];
    if (!isSaved) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(accelerometerError:)]) {
            [self.delegate accelerometerError:error];
        }
    }
}

#pragma mark - Utility methods
- (NSString *) createFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/accelerometer.csv", documentsDirectory];
    return fileName;
}

@end
