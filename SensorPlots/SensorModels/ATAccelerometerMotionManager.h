//
//  ATSMotionAccelerometerManager.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/3/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import <MessageUI/MessageUI.h>
#import "ATSMotionAccelerometerManagerDelegate.h"

@interface ATAccelerometerMotionManager : CMMotionManager

@property (strong, nonatomic) id<ATAccelerometerMotionManagerDelegate> delegate;
@property (strong, nonatomic) NSNumber *refreshRateHz;

// Initilizers
- (instancetype) initWithUpdateInterval: (NSNumber *) updateInterval;

// Accessor methods to be called by user

// How many points are stored in CoreData table - "AccelerometerData"
- (NSNumber *) savedCountOfAcclerometerDataPoints;
// Setup the accelerometer update interval in Hz. 1 to 100 Hz.
- (NSNumber *) accelerometerUpdateInterval: (NSNumber *) intervalHzWithDouble;
- (BOOL) accelerometerUpdateBackgroundMode: (BOOL) mode;
- (BOOL) getAccelerometerBackgroundMode; // Get stored background mode

// Start the Acceleromter tests if it is not already running.
- (void) startAccelerometerUpdates;
- (void) startAccelerometerUpdatesWithInterval: (NSNumber *) intervalHzWithDouble;

// Stop the accelerometer updates.
- (void) stopAccelerometerUpdates;

// Trash all the data in CoreData, File and memory.
- (void) trashAccelerometerStoredData;

// A composer with a all data attachement.
- (MFMailComposeViewController *) emailComposerWithAccelerometerData;

@end
