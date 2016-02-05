//
//  ATGyroMotionManagerDelegate.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ATGyroMotionManagerDelegate <NSObject>

// Informs results and status from 'ATMotionGyroManager'
@required
// Called when test results are ready
- (void) didFinishGyroUpdateWithResults: (NSArray *) results;

@optional
// A single method that calls with all errors.
- (void) gyroError: (NSError *) error;
// Update when Nth data point was received.
- (void) gyroProgressUpdate: (UInt32) count;
// Update when test is about to be started. Can update UX here
- (void) willStartGyroUpdate;
// Update when test started. Can update UX here
- (void) didStartGyroUpdate;
// Update when test is stopped. Can update UX here
- (void) didStopGyroUpdate;
// Update when all test data is deleted - database, composer file. Can update UX here
- (void) didTrashGyroDataCache;

@end
