//
//  ATSensorData.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/6/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATSensorData : NSObject

@property (nonatomic) double x;
@property (nonatomic) double y;
@property (nonatomic) double z;
@property (nonatomic) NSTimeInterval timestamp;

- (instancetype) initWithUpdateX:(double)x Y:(double)y Z:(double)z timeInterval:(NSTimeInterval)interval;

@end
