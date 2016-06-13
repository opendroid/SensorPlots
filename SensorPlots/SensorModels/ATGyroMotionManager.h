//
//  ATGyroMotionManager.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import <MessageUI/MessageUI.h>
#import "ATGyroMotionManagerDelegate.h"

@interface ATGyroMotionManager : CMMotionManager

@property (strong, nonatomic) id<ATGyroMotionManagerDelegate> delegate;
@property (strong, nonatomic) NSNumber *refreshRateHz;

// Initilizers
- (instancetype) initWithUpdateInterval: (NSNumber *) updateInterval;

// Accessor methods to be called by user

// How many points are stored in CoreData table - "GyroData"
- (NSNumber *) savedCountOfGyroDataPoints;
// Setup the Gyro update interval in Hz. 1 to 100 Hz.
- (NSNumber *) gyroUpdateInterval: (NSNumber *) intervalHzWithDouble;

// Start the Gyro tests if it is not already running.
- (void) startGyroUpdates;
- (void) startGyroUpdatesWithInterval:(NSNumber *) intervalHzWithDouble;

// Stop the Gyro updates.
- (void) stopGyroUpdates;

// Trash all the data in CoreData, File and memory.
- (void) trashGyroStoredData;

// A composer with a all data attachement.
- (MFMailComposeViewController *) emailComposerWithGyroData;

@end
