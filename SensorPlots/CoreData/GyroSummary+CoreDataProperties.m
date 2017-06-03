//
//  GyroSummary+CoreDataProperties.m
//  SensorPlots
//
//  Created by Ajay Thakur on 12/25/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "GyroSummary+CoreDataProperties.h"

@implementation GyroSummary (CoreDataProperties)

+ (NSFetchRequest<GyroSummary *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"GyroSummary"];
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
