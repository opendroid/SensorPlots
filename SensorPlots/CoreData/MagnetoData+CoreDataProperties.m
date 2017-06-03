//
//  MagnetoData+CoreDataProperties.m
//  SensorPlots
//
//  Created by Ajay Thakur on 12/25/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "MagnetoData+CoreDataProperties.h"

@implementation MagnetoData (CoreDataProperties)

+ (NSFetchRequest<MagnetoData *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"MagnetoData"];
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
