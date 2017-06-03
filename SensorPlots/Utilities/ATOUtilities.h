//
//  ATOUtilities.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ATOUtilities : NSObject

+ (NSString *) createDataFilePathForName: (NSString *) fileName;
+ (void) showAppAlertWithMessage: (NSString *) message andViewController: (UIViewController *) vc;
+ (NSNumber *) getAccelerometerConfigurationFromNSU;
+ (NSNumber *) getGyroConfigurationFromNSU;
+ (NSNumber *) getMagnetoConfigurationFromNSU;

+ (BOOL) getAccelerometerBackgroundMode;
+ (BOOL) getGyroBackgroundMode;
+ (BOOL) getMagnetoBackgroundMode;

+ (NSDictionary *) getGpsConfigurationFromNSU;
+ (void) saveGpsConfig: (NSDictionary *) gpsConfigData;

+ (NSNumber *) savedCountOfGyroDataPoints;
+ (NSNumber *) savedCountOfMagnetoDataPoints;
+ (NSNumber *) savedCountOfAcceleroDataPoints;
+ (NSNumber *) savedCountOfLocationDataPoints;

+ (NSNumber *) nextTestIDForGyroUpdates;
+ (NSNumber *) nextTestIDForMagnetoUpdates;
+ (NSNumber *) nextTestIDForAcceleroUpdates;
+ (NSNumber *) nextTestIDForLocationDataUpdates;

@end
