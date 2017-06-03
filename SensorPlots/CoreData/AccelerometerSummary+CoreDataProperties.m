//
//  AccelerometerSummary+CoreDataProperties.m
//  SensorPlots
//
//  Created by Ajay Thakur on 12/25/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "AccelerometerSummary+CoreDataProperties.h"

@implementation AccelerometerSummary (CoreDataProperties)

+ (NSFetchRequest<AccelerometerSummary *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"AccelerometerSummary"];
}

@dynamic endTime;
@dynamic isProcessed;
@dynamic maxRMS;
@dynamic minRMS;
@dynamic nSamples;
@dynamic startTime;
@dynamic testID;
@dynamic testType;

@end
