//
//  NSDate+BootTime.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/2/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (BootTime)

+ (NSDate *)bootTime;
+ (NSTimeInterval)bootTimeTimeIntervalSinceReferenceDate;

@end
