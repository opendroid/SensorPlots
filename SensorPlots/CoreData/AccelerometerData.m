//
//  AccelerometerData.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/2/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "AccelerometerData.h"
#import "NSDate+BootTime.h"

@implementation AccelerometerData

// Insert code here to add functionality to your managed object subclass
+ (NSSet *) keyPathsForValuesAffectingGValue {
    return [NSSet setWithObjects:@"x", @"y", @"z", nil];
}

+ (NSSet *) keyPathsForValuesAffectingTimestamp {
    return [NSSet setWithObjects:@"timeinterval", nil];
}
- (NSNumber *) gValue {
    double value = (self.x.doubleValue * self.x.doubleValue) + (self.y.doubleValue * self.y.doubleValue) + (self.z.doubleValue * self.z.doubleValue);
    value = sqrt(value);
    return [NSNumber numberWithDouble:value];
}

- (NSDate *) timestamp {
    NSDate *bootTime = [NSDate bootTime];
    NSDate *sampleTime = [NSDate dateWithTimeInterval:self.timeinterval.doubleValue sinceDate:bootTime];
    return sampleTime;
}

@end
