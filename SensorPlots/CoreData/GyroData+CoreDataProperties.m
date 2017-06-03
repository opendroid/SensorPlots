//
//  GyroData+CoreDataProperties.m
//  SensorPlots
//
//  Created by Ajay Thakur on 12/25/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "GyroData+CoreDataProperties.h"

@implementation GyroData (CoreDataProperties)

+ (NSFetchRequest<GyroData *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"GyroData"];
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
