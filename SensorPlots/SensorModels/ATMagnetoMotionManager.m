//
//  ATMagnetoMotionManager.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "ATMagnetoMotionManager.h"
#import "AppDelegate.h"
#import "MagnetoData.h"
#import "ATOUtilities.h"


@interface ATMagnetoMotionManager()

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableArray *dataArray; // Values of Magneto are saved here.
@property (strong, nonatomic) AppDelegate *appDelegate;

@property (atomic) BOOL magnetoUpdatesInProgress;
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
        self.dataArray = [[NSMutableArray alloc] init];
    }
    if ((!self.motionManager) || (!self.managedObjectContext) || (!self.dataArray) ) {
        return nil; // Initilization failed.
    }
    self.magnetoUpdatesInProgress = NO;
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
    
    if(self.magnetoUpdatesInProgress) {
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
    [self.dataArray removeAllObjects]; // Remove old data
    self.magnetoUpdatesInProgress = YES;
    NSOperationQueue *opsQueue = [[NSOperationQueue alloc] init];
    opsQueue.name = @"SPTMagneto";
    // relatively higher QoS but lower than User interation so they can stop the updates
    opsQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    self.motionManager.magnetometerUpdateInterval = 1.0 / self.refreshRateHz.floatValue;
    [self.motionManager startMagnetometerUpdatesToQueue:opsQueue withHandler:^(CMMagnetometerData * _Nullable magnetoData, NSError * _Nullable error) {
        if (error || !self.magnetoUpdatesInProgress){
            return; // Dont save data after test is stopped
        }
        // Save it in memory array
        [self.dataArray addObject:magnetoData];
        
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
    // Check if test was running
    if(!self.magnetoUpdatesInProgress) {
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
    
    // Stop the test.
    self.magnetoUpdatesInProgress = NO;
    [self.motionManager stopMagnetometerUpdates];
    
    // Protocol - did stop the test
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStopMagnetoUpdate)]) {
        [self.delegate didStopMagnetoUpdate];
    }
    
    // save data to CoreData
    [self saveMagnetoDataToCoreData];
    
    // Pass on the results
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishMagnetoUpdateWithResults:)]) {
        [self.delegate didFinishMagnetoUpdateWithResults:self.dataArray];
    }
}


- (MFMailComposeViewController *) emailComposerWithMagnetoData {
    //Get a file name to write the data to using the documents directory:
    NSString *fileName = [ATOUtilities createDataFilePathForName:@"Magneto.csv"];
    
    // Read contents from CoreData table and store in a NSMutableString
    NSMutableString *coreDataString = [[NSMutableString alloc] init];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MagnetoData"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timeInterval" ascending:NO]];
    NSError *fetchError;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    [coreDataString appendString:@"x_micro_tesla,y_micro_tesla,z_micro_tesla,rms_micro_tesla,TimeInterval,Date\n"];
    
    // Extract the data
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS Z";
    for (MagnetoData *d in results) {
        NSString *dateTime = [formatter stringFromDate:d.timestamp];
        NSString *rowData = [NSString stringWithFormat:@"%f,%f,%f,%f,%f,%@\n", d.x.doubleValue, d.y.doubleValue, d.z.doubleValue, d.avgValue.doubleValue, d.timeInterval.doubleValue, dateTime];
        [coreDataString appendString:rowData];
    }
    
    // Save contents to a CSV file.
    [coreDataString writeToFile:fileName  atomically:YES  encoding:NSUTF8StringEncoding error:nil];
    NSData *fileData = [NSData dataWithContentsOfFile:fileName];
    
    // Create the Email message with attachment and compose a viewer
    NSString *emailTitle = @"PlutoApps: Your Magneto test data"; // Email Subject
    NSString *messageBody = @"Your data is in attached file Magneto.csv. The units are in Micro Tesla."
                " The data are sorted by timestamp in decending order."
                " If you have questions email me at plutoapps@outlook.com\n";
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc addAttachmentData:fileData mimeType:@"text/csv" fileName:@"Magneto.csv"];
    
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
    NSString *filePathName = [ATOUtilities createDataFilePathForName:@"Magneto.csv"];
    [[NSFileManager defaultManager] removeItemAtPath:filePathName error:&deleteError];
    if (deleteError && self.delegate && [self.delegate respondsToSelector:@selector(magnetoError:)]) {
        [self.delegate magnetoError:deleteError];
    }
    
    // 3. Clear Memory
    [self.dataArray removeAllObjects];
    
    // Protocol - completed trashing the data
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTrashMagnetoDataCache)]) {
        [self.delegate didTrashMagnetoDataCache];
    }
}

#pragma mark - Core Data Table
- (void) saveMagnetoDataToCoreData {
    
    for (CMMagnetometerData *d in self.dataArray) {
        MagnetoData *data = [NSEntityDescription insertNewObjectForEntityForName:@"MagnetoData" inManagedObjectContext:self.managedObjectContext];
        data.x = [NSNumber numberWithDouble:d.magneticField.x];
        data.y = [NSNumber numberWithDouble:d.magneticField.y];
        data.z = [NSNumber numberWithDouble:d.magneticField.z];
        data.timeInterval = [NSNumber numberWithDouble:d.timestamp]; // Time since last phone bootup.
    }
    
    NSError *error;
    BOOL isSaved = [self.managedObjectContext save:&error];
    if (!isSaved) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(magnetoError:)]) {
            [self.delegate magnetoError:error];
        }
    }
}




@end
