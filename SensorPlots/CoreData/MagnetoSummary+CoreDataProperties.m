//
//  MagnetoSummary+CoreDataProperties.m
//  SensorPlots
//
//  Created by Ajay Thakur on 12/25/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "MagnetoSummary+CoreDataProperties.h"

@implementation MagnetoSummary (CoreDataProperties)

+ (NSFetchRequest<MagnetoSummary *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"MagnetoSummary"];
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
