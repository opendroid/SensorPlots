//
//  GyroData.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "GyroData.h"
#import "NSDate+BootTime.h"

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
    NSDate *bootTime = [NSDate bootTime];
    NSDate *sampleTime = [NSDate dateWithTimeInterval:self.timeInterval.doubleValue sinceDate:bootTime];
    return sampleTime;
}

@end
