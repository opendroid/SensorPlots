//
//  SPTConstants.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/7/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifndef SPTConstants_h
#define SPTConstants_h

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define IS_OS_42_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 4.2)

// Debug
FOUNDATION_EXPORT BOOL const kATDebugON;
FOUNDATION_EXPORT BOOL const kATDebugDetailON;
FOUNDATION_EXPORT BOOL const kATDebugErrorON;
FOUNDATION_EXPORT BOOL const kATDebugDelayON;

// These constants are used as VC names for tracking using GA
FOUNDATION_EXPORT NSString *const kATAcceleroVC;
FOUNDATION_EXPORT NSString *const kATGyroVC;
FOUNDATION_EXPORT NSString *const kATMagnetoVC;
FOUNDATION_EXPORT NSString *const kATGpsVC;

FOUNDATION_EXPORT NSString *const kATAcceleroTestEvent;
FOUNDATION_EXPORT NSString *const kATGyroTestEvent;
FOUNDATION_EXPORT NSString *const kATMagnetoTestEvent;
FOUNDATION_EXPORT NSString *const kATGpsCaptureEvent;

// String constants to compose email for sending sensor data
// These contsants are mostly used by AT*MotionManager.m models
FOUNDATION_EXPORT NSString *const kATEmailSubjectAccelero;
FOUNDATION_EXPORT NSString *const kATEmailBodyAccelero;
FOUNDATION_EXPORT NSString *const kATCSVDataFilenameAccelero;
FOUNDATION_EXPORT NSString *const kATEmailSubjectGyro;
FOUNDATION_EXPORT NSString *const kATEmailBodyGyro;
FOUNDATION_EXPORT NSString *const kATCSVDataFilenameGyro;
FOUNDATION_EXPORT NSString *const kATEmailSubjectMagneto;
FOUNDATION_EXPORT NSString *const kATEmailBodyMagneto;
FOUNDATION_EXPORT NSString *const kATCSVDataFilenameMagneto;
FOUNDATION_EXPORT NSString *const kATEmailSubjectGps;
FOUNDATION_EXPORT NSString *const kATEmailBodyGps;
FOUNDATION_EXPORT NSString *const kATCSVDataFilenameGps;

// Number of samples
FOUNDATION_EXPORT NSUInteger const kATIncomingQMaxCount; // Maximum deapth of incoming queue
FOUNDATION_EXPORT NSUInteger const kATMinXValueOnGraph; // Max samples to display
FOUNDATION_EXPORT NSUInteger const kATMaxXLengthOnGraph; // Max samples to display
FOUNDATION_EXPORT NSUInteger const kATxAxisLengthOnScreenDefault;

FOUNDATION_EXPORT NSUInteger const kATMaxNumberOfSamples;

// Define Graph constants and limits for Accelerometer
FOUNDATION_EXPORT double const kATxAxisMinimumAccelero; // x-minimum
FOUNDATION_EXPORT double const kATxAxisLengthOnScreenAccelero; // x-max on screen
FOUNDATION_EXPORT double const kATxAxisLengthMaxAccelero; // x-max on screen
FOUNDATION_EXPORT double const kATxAxisIntervalAccelero; // x-major axis lines
FOUNDATION_EXPORT NSUInteger const kATxAxisTicksInIntervalAccelero; // x-minor axis
FOUNDATION_EXPORT double const kATyAxisMinimumAccelero; // y-minimum
FOUNDATION_EXPORT double const kATyAxisLengthAccelero; // y - max
FOUNDATION_EXPORT double const kATyAxisIntervalAccelero; //  y-major axis lines
FOUNDATION_EXPORT NSUInteger const kATyAxisTicksInIntervalAccelero; // y-minor axix

// Define Graph constants and limits for Gyro
FOUNDATION_EXPORT double const kATxAxisMinimumGyro; // x-minimum
FOUNDATION_EXPORT double const kATxAxisLengthOnScreenGyro; // x-max on screen
FOUNDATION_EXPORT double const kATxAxisLengthMaxGyro; // x-max on screen
FOUNDATION_EXPORT double const kATxAxisIntervalGyro; // x-major axis lines
FOUNDATION_EXPORT NSUInteger const kATxAxisTicksInIntervalGyro; // x-minor axis
FOUNDATION_EXPORT double const kATyAxisMinimumGyro; // y-minimum
FOUNDATION_EXPORT double const kATyAxisLengthGyro; // y - max
FOUNDATION_EXPORT double const kATyAxisIntervalGyro; //  y-major axis lines
FOUNDATION_EXPORT NSUInteger const kATyAxisTicksInIntervalGyro; // y-minor axix

// Define Graph constants and limits for Magneto
FOUNDATION_EXPORT double const kATxAxisMinimumMagneto;
FOUNDATION_EXPORT double const kATxAxisLengthOnScreenMagneto;
FOUNDATION_EXPORT double const kATxAxisLengthMaxMagneto;
FOUNDATION_EXPORT double const kATxAxisIntervalMagneto;
FOUNDATION_EXPORT NSUInteger const kATxAxisTicksInIntervalMagneto;
FOUNDATION_EXPORT double const kATyAxisMinimumMagneto;
FOUNDATION_EXPORT double const kATyAxisLengthMagneto;
FOUNDATION_EXPORT double const kATyAxisIntervalMagneto;
FOUNDATION_EXPORT NSUInteger const kATyAxisTicksInIntervalMagneto;

// Thee constants are used by Gps Graph VC that displays graphs
FOUNDATION_EXPORT NSUInteger const kATGpsMaxPointsToPlot;

// Define keys to store GPS configuration items in NSU
FOUNDATION_EXPORT NSString *const kATGpsConfigKey;
FOUNDATION_EXPORT NSString *const kATGpsIsBackgroundOnKey;
FOUNDATION_EXPORT NSString *const kATGpsUpdateKey;
FOUNDATION_EXPORT NSString *const kATGpsUpdateUILKey;
FOUNDATION_EXPORT NSString *const kATGpsAccuracyKey;
FOUNDATION_EXPORT NSString *const kATGpsAccuracyUISKey;
FOUNDATION_EXPORT NSString *const kATGpsAccuracyUILKey;
FOUNDATION_EXPORT NSString *const kATGpsActivityKey;
FOUNDATION_EXPORT NSString *const kATGpsActivityUISKey;
FOUNDATION_EXPORT NSString *const kATGpsActivityUILKey;

// Define keys to store Map configuration items in NSU
FOUNDATION_EXPORT NSString *const kATMapTypeConfigKey;

#endif /* Constants_h */