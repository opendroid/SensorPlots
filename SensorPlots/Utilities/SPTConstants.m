//
//  SPTConstants.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/7/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "SPTConstants.h"

BOOL const kATDebugON = YES; // enable debug
BOOL const kATDebugDetailON = YES; // detail debugs
BOOL const kATDebugErrorON = YES; // Show erros NSLOG
BOOL const kATDebugDelayON = YES; // For testing


// These constants are used as VC names for tracking using GA
NSString *const kATAcceleroVC = @"PageAccelero";
NSString *const kATGyroVC = @"PageGyro";
NSString *const kATMagnetoVC = @"PageMagneto";
NSString *const kATGpsVC = @"PageGps";
NSString *const kATSettingsVC = @"PageSettings";

NSString *const kATAcceleroTestEvent = @"CaptureAccelero";
NSString *const kATGyroTestEvent = @"CaptureGyro";
NSString *const kATMagnetoTestEvent = @"CaptureMagneto";
NSString *const kATGpsCaptureEvent = @"CaptureGps";

// 'Text for emails' database keys
NSString *const kATEmailSubjectAccelero = @"PlutoApps: Your accelerometer data";
NSString *const kATEmailBodyAccelero = @"Your data is in attached file  SensorPlotsAccelero.csv. "\
                    "The units are in multiples of earth's gravity. So x = 2.1 means x is "\
                    "2.1 times g (=9.8 m/second sq.). The data are sorted by timestamp in "\
                    "decending order. The date format is yyyy-MM-dd HH:mm:ss.SSSSSS Z. If you "\
                    "have questions, email me at plutoapps@outlook.com\n";
NSString *const kATCSVDataFilenameAccelero = @"SensorPlotsAccelero.csv";


NSString *const kATEmailSubjectGyro = @"PlutoApps: Your Gyro data";
NSString *const kATEmailBodyGyro = @"Your data is in attached file SensorPlotsGyro.csv. "\
                        "The units are in radians per second. The data are sorted "\
                        "by timestamp in decending order. The date format is "\
                        "yyyy-MM-dd HH:mm:ss.SSSSSS Z. If you have questions, email me at "\
                        "plutoapps@outlook.com\n";
NSString *const kATCSVDataFilenameGyro = @"SensorPlotsGyro.csv";

// Gyro.csv
NSString *const kATEmailSubjectMagneto = @"PlutoApps: Your Magneto data";
NSString *const kATEmailBodyMagneto = @"Your data is in attached file SensorPlotsMagneto.csv. "\
                        "The units are in Micro Tesla. The data are sorted by timestamp "\
                        "in decending order. The date format is yyyy-MM-dd HH:mm:ss.SSSSSS Z. "\
                        "If you have questions email me at plutoapps@outlook.com\n";
NSString *const kATCSVDataFilenameMagneto = @"SensorPlotsMagneto.csv";

// Location.csv
NSString *const kATEmailSubjectGps = @"PlutoApps: Your Locations data";
NSString *const kATEmailBodyGps = @"Your data is in attached file SensorPlotsLocations.csv. "\
"The data are sorted by timestamp in decending order. The date format is yyyy-MM-dd HH:mm:ss.SSSSSS Z. "\
"If you have questions email me at "\
"plutoapps@outlook.com\n";
NSString *const kATCSVDataFilenameGps = @"SensorPlotsLocations.csv";

// Globals Graph values
NSUInteger const kATIncomingQMaxCount = 2000;
NSUInteger const kATMaxNumberOfSamples = 600;
NSUInteger const kATMinXValueOnGraph=-50;
NSUInteger const kATxAxisLengthOnScreenDefault=225;
NSUInteger const kATMaxXLengthOnGraph = kATMaxNumberOfSamples-kATMinXValueOnGraph;

// Thee constants are used by Accelerometer Graph VC that displays graphs
double const kATxAxisMinimumAccelero = -25.0;
double const kATxAxisLengthOnScreenAccelero = 225.0;
double const kATxAxisLengthMaxAccelero = kATMaxXLengthOnGraph;
double const kATxAxisIntervalAccelero = 100.0;
NSUInteger const kATxAxisTicksInIntervalAccelero = 4;
double const kATyAxisMinimumAccelero = -2.0;
double const kATyAxisLengthAccelero = 4.0;
double const kATyAxisIntervalAccelero= 1.0;
NSUInteger const kATyAxisTicksInIntervalAccelero=4;


// Thee constants are used by Gyro Graph VC that displays graphs
double const kATxAxisMinimumGyro = -25.0;
double const kATxAxisLengthOnScreenGyro = 225.0;
double const kATxAxisLengthMaxGyro = kATMaxXLengthOnGraph;
double const kATxAxisIntervalGyro = 100.0;
NSUInteger const kATxAxisTicksInIntervalGyro = 4;
double const kATyAxisMinimumGyro = -20.0;
double const kATyAxisLengthGyro = 40.0;
double const kATyAxisIntervalGyro= 10.0;
NSUInteger const kATyAxisTicksInIntervalGyro=4;

// Thee constants are used by Gyro Graph VC that displays graphs
double const kATxAxisMinimumMagneto = -50.0;
double const kATxAxisLengthOnScreenMagneto = 250.0;
double const kATxAxisLengthMaxMagneto = kATMaxXLengthOnGraph;
double const kATxAxisIntervalMagneto=100.0;
NSUInteger const kATxAxisTicksInIntervalMagneto=4;
double const kATyAxisMinimumMagneto=-500;
double const kATyAxisLengthMagneto=1000;
double const kATyAxisIntervalMagneto=200;
NSUInteger const kATyAxisTicksInIntervalMagneto=4;

// Thee constants are used by Gps Graph VC that displays graphs
NSUInteger const kATGpsMaxPointsToPlot = 30000;

// Define keys to store GPS configuration items in NSU
NSString *const kATMagnetoBackgroundConfigKey = @"SPTMagnetoBackgroundConfig";
NSString *const kATGyroBackgroundConfigKey = @"SPTGyroBackgroundConfig";
NSString *const kATAcceleroBackgroundConfigKey = @"SPTAcceleroBackgroundConfig";

NSString *const kATMagnetoSampleRateHzKey = @"SPTMagnetoHzSetting";
NSString *const kATGyroSampleRateHzKey = @"SPTGyroHzSetting";
NSString *const kATAcceleroSampleRateHzKey = @"SPTAccelerometerHzSetting";

NSString *const kATGpsConfigKey = @"SPTGpsConfiguration";
NSString *const kATGpsIsBackgroundOnKey = @"SPTGpsBackgroundMode";
NSString *const kATGpsUpdateKey = @"SPTGpsUpdate";
NSString *const kATGpsUpdateUILKey = @"SPTGpsUpdateUIL";
NSString *const kATGpsAccuracyKey = @"SPTGpsAccuracy"; 
NSString *const kATGpsAccuracyUISKey = @"SPTGpsAccuracyUIS";
NSString *const kATGpsAccuracyUILKey = @"SPTGpsAccuracyUIL";
NSString *const kATGpsActivityKey = @"SPTGpsActivity";
NSString *const kATGpsActivityUISKey = @"SPTGpsActivityUIS";
double const kATMetersPerSecToMPH = 2.23694;

// Define keys to store Map configuration items in NSU
NSString *const kATMapTypeConfigKey = @"SPTMapTypeConfiguration";


