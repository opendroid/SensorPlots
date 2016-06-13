//
//  ATSensorData.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/6/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "ATSensorData.h"

@implementation ATSensorData

- (instancetype) init {
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (instancetype) initWithUpdateX:(double)x Y:(double)y Z:(double)z timeInterval:(NSTimeInterval)interval {
    if (self = [self init]) {
        self.x = x;
        self.y = y;
        self.z = z;
        self.timestamp = interval;
    }
    return self;
}


@end
