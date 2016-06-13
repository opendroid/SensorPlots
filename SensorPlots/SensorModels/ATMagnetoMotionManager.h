//
//  ATMagnetoMotionManager.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import <MessageUI/MessageUI.h>
#import "ATMagnetoMotionManagerDelegate.h"

@interface ATMagnetoMotionManager : CMMotionManager

@property (strong, nonatomic) id<ATMagnetoMotionManagerDelegate> delegate;
@property (strong, nonatomic) NSNumber *refreshRateHz;

// Initilizers
- (instancetype) initWithUpdateInterval: (NSNumber *) updateInterval;

// Accessor methods to be called by user

// How many points are stored in CoreData table - "Magneto"
- (NSNumber *) savedCountOfMagnetoDataPoints;
// Setup the Magneto update interval in Hz. 1 to 100 Hz.
- (NSNumber *) magnetoUpdateInterval: (NSNumber *) intervalHzWithDouble;

// Start the Magneto tests if it is not already running.
- (void) startMagnetoUpdates;
- (void) startMagnetoUpdatesWithInterval: (NSNumber *) intervalHzWithDouble;

// Stop the Magneto updates.
- (void) stopMagnetoUpdates;

// Trash all the data in CoreData, File and memory.
- (void) trashMagnetoStoredData;

// A composer with a all data attachement.
- (MFMailComposeViewController *) emailComposerWithMagnetoData;


@end
