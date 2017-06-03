//
//  LocationSummary+CoreDataProperties.m
//  SensorPlots
//
//  Created by Ajay Thakur on 12/25/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "LocationSummary+CoreDataProperties.h"

@implementation LocationSummary (CoreDataProperties)

+ (NSFetchRequest<LocationSummary *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"LocationSummary"];
}

@dynamic averageSpeed;
@dynamic distanceMeters;
@dynamic endTime;
@dynamic isProcessed;
@dynamic maxSpeed;
@dynamic minSpeed;
@dynamic nSamples;
@dynamic startTime;
@dynamic testID;
@dynamic testType;

@end
