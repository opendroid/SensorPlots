//
//  ATMagnetoMotionManagerDelegate.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ATMagnetoMotionManagerDelegate <NSObject>

// Informs results and status from 'ATMagnetoMotionManager'
@required
// Called when test results are ready
- (void) didFinishMagnetoUpdateWithResults: (NSArray *) results maxSampleValue: (NSNumber *) max minSampleValue:(NSNumber *) min;

@optional
// A single method that calls with all errors.
- (void) magnetoError: (NSError *) error;
// Update when Nth data point was received.
- (void) magnetoProgressUpdate: (UInt32) count;
// Update when test is about to be started. Can update UX here
- (void) willStartMagnetoUpdate;
// Update when test started. Can update UX here
- (void) didStartMagnetoUpdate;
// Update when test is stopped. Can update UX here
- (void) didStopMagnetoUpdate;
// Update when all test data is deleted - database, composer file. Can update UX here
- (void) didTrashMagnetoDataCache;

@end
