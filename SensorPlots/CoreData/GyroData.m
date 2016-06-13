//
//  GyroData.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "GyroData.h"

@implementation GyroData

// Insert code here to add functionality to your managed object subclass
+ (NSSet *) keyPathsForValuesAffectingAvgValue {
    return [NSSet setWithObjects:@"x", @"y", @"z", nil];
}

+ (NSSet *) keyPathsForValuesAffectingTimestamp {
    return [NSSet setWithObjects:@"timeInterval", nil];
}
- (NSNumber *) avgValue {
    double value = (self.x.doubleValue * self.x.doubleValue) + (self.y.doubleValue * self.y.doubleValue) + (self.z.doubleValue * self.z.doubleValue);
    value = sqrt(value);
    return [NSNumber numberWithDouble:value];
}

- (NSDate *) timestamp {
    NSTimeInterval sampleTimeInPast = self.timeInterval.doubleValue - [[NSProcessInfo processInfo] systemUptime];
    NSDate *sampleTime = [NSDate dateWithTimeIntervalSinceNow:sampleTimeInPast];
    return sampleTime;
}

@end
