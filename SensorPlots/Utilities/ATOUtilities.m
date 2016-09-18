//
//  ATOUtilities.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//
#import "AppDelegate.h"
#import "ATOUtilities.h"
#import "SPTConstants.h"
@import CoreLocation;
@import MapKit;

@implementation ATOUtilities

+ (NSString *) createDataFilePathForName: (NSString *) fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fullPathFileName = [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
    return fullPathFileName;
}

#pragma mark - Utility methods
// Show 'showAppAlertWithMessage' a utility to show a alert message
+ (void) showAppAlertWithMessage: (NSString *) message
               andViewController: (UIViewController *) vc {
    UIAlertController *okVC = [UIAlertController alertControllerWithTitle:@"Sensor Plots" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [okVC addAction:okAction];
    [vc presentViewController:okVC animated:YES completion:nil];
}

#pragma mark - Retriving Frequecy Rate data from NSU
/**
  * Utilities to get the Refresh Rate Settings from NSUserDefaults
  */
+ (NSNumber *) getAccelerometerConfigurationFromNSU {
    NSNumber *freqHz =  [[NSUserDefaults standardUserDefaults] objectForKey:kATAcceleroSampleRateHzKey];
    if (!freqHz) {
        freqHz = [[NSNumber alloc] initWithFloat:33.0];
        [[NSUserDefaults standardUserDefaults] setObject:freqHz forKey:kATAcceleroSampleRateHzKey];
    }
    return freqHz;
}

+ (NSNumber *) getGyroConfigurationFromNSU {
    NSNumber *freqHz =  [[NSUserDefaults standardUserDefaults] objectForKey:kATGyroSampleRateHzKey];
    if (!freqHz) {
        freqHz = [[NSNumber alloc] initWithFloat:33.0];
        [[NSUserDefaults standardUserDefaults] setObject:freqHz forKey:kATGyroSampleRateHzKey];
    }
    return freqHz;
}

+ (NSNumber *) getMagnetoConfigurationFromNSU {
    NSNumber *freqHz =  [[NSUserDefaults standardUserDefaults] objectForKey:kATMagnetoSampleRateHzKey];
    if (!freqHz) {
        freqHz = [[NSNumber alloc] initWithFloat:33.0];
        [[NSUserDefaults standardUserDefaults] setObject:freqHz forKey:kATMagnetoSampleRateHzKey];
    }
    return freqHz;
}

#pragma mark - Retriving Background Mode data from NSU
/**
 * Utilities to get the Background Mode from NSUserDefaults
 */
+ (BOOL) getAccelerometerBackgroundMode {
    BOOL mode =  [[NSUserDefaults standardUserDefaults] boolForKey:kATAcceleroBackgroundConfigKey];
    return mode;
}

+ (BOOL) getGyroBackgroundMode {
    BOOL mode =  [[NSUserDefaults standardUserDefaults] boolForKey:kATGyroBackgroundConfigKey];
    return mode;
}

+ (BOOL) getMagnetoBackgroundMode {
    BOOL mode =  [[NSUserDefaults standardUserDefaults] boolForKey:kATMagnetoBackgroundConfigKey];
    return mode;
}

#pragma mark - Retriving Background Mode data from NSU
+ (void) saveGpsConfig: (NSDictionary *) gpsConfigData {
    [[NSUserDefaults standardUserDefaults] setObject:gpsConfigData forKey:kATGpsConfigKey];
}

+ (NSDictionary *) getGpsConfigurationFromNSU {
    NSDictionary *gpsConfig =  [[NSUserDefaults standardUserDefaults] objectForKey:kATGpsConfigKey];
    if (!gpsConfig) {
        // Set up defaults if no data is available.
        gpsConfig = [NSDictionary dictionaryWithObjectsAndKeys:
                     [NSNumber numberWithBool:FALSE], kATGpsIsBackgroundOnKey,
                     [NSNumber numberWithDouble:100.0], kATGpsUpdateKey,
                     @"100.0 Mts", kATGpsUpdateUILKey,
                     [NSNumber numberWithDouble:kCLLocationAccuracyBest], kATGpsAccuracyKey,
                     [NSNumber numberWithDouble:2.0], kATGpsAccuracyUISKey,
                     @"Best", kATGpsAccuracyUILKey,
                     [NSNumber numberWithInteger:CLActivityTypeAutomotiveNavigation], kATGpsActivityKey,
                     [NSNumber numberWithDouble:2.0], kATGpsActivityUISKey,
                     [NSNumber numberWithInteger:MKMapTypeStandard], kATMapTypeConfigKey,
                     nil];
        [self saveGpsConfig:gpsConfig];
    }
    return gpsConfig;
}

#pragma mark - Retriving Background Mode data from CoreData

+ (NSNumber *) savedCountOfDataPointsForTable: (NSString *) tableName {
    // Check if there is data in 'MagnetoData' to send.
    AppDelegate *appDelegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:tableName];
    fetchRequest.resultType = NSCountResultType;
    NSError *fetchError = nil;
    NSUInteger itemsCount = [appDelegate.managedObjectContext countForFetchRequest:fetchRequest error:&fetchError];
    if (itemsCount == NSNotFound) {
        itemsCount = 0;
    }
    NSNumber *item = [NSNumber numberWithInteger:itemsCount];
    return item;
}

+ (NSNumber *) savedCountOfGyroDataPoints {
    return [ATOUtilities savedCountOfDataPointsForTable:@"GyroData"];
}

+ (NSNumber *) savedCountOfMagnetoDataPoints {
    return [ATOUtilities savedCountOfDataPointsForTable:@"MagnetoData"];
}

+ (NSNumber *) savedCountOfAcceleroDataPoints {
    return [ATOUtilities savedCountOfDataPointsForTable:@"AccelerometerData"];;
}

+ (NSNumber *) savedCountOfLocationDataPoints {
    return [ATOUtilities savedCountOfDataPointsForTable:@"LocationData"];;
}

@end
