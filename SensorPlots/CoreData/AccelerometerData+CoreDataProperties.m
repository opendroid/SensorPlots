//
//  AccelerometerData+CoreDataProperties.m
//  SensorPlots
//
//  Created by Ajay Thakur on 12/25/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "AccelerometerData+CoreDataProperties.h"

@implementation AccelerometerData (CoreDataProperties)

+ (NSFetchRequest<AccelerometerData *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"AccelerometerData"];
}

@dynamic avgValue;
@dynamic sampleID;
@dynamic testID;
@dynamic timeInterval;
@dynamic timestamp;
@dynamic x;
@dynamic y;
@dynamic z;

@end
