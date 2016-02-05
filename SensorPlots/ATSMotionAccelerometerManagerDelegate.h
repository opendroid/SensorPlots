//
//  ATSMotionAccelerometerManagerDelegate.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/3/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ATAccelerometerMotionManagerDelegate <NSObject>

// Informs results and status from 'ATMotionAccelerometerManager'
@required
// Called when test results are ready
- (void) didFinishAccelerometerUpdateWithResults: (NSArray *) results;

@optional
// A single method that calls with all errors.
- (void) accelerometerError: (NSError *) error;
// Update when Nth data point was received.
- (void) accelerometerProgressUpdate: (UInt32) count;
// Update when test is about to be started. Can update UX here
- (void) willStartAccelerometerUpdate;
// Update when test started. Can update UX here
- (void) didStartAccelerometerUpdate;
// Update when test is stopped. Can update UX here
- (void) didStopAccelerometerUpdate;
// Update when all test data is deleted - database, composer file. Can update UX here
- (void) didTrashAccelerometerDataCache;

@end
