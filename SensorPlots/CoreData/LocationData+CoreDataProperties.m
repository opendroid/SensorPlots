//
//  LocationData+CoreDataProperties.m
//  SensorPlots
//
//  Created by Ajay Thakur on 12/25/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "LocationData+CoreDataProperties.h"

@implementation LocationData (CoreDataProperties)

+ (NSFetchRequest<LocationData *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"LocationData"];
}

@dynamic altitude;
@dynamic course;
@dynamic horizontalAccuracy;
@dynamic latitude;
@dynamic locationID;
@dynamic longitude;
@dynamic speed;
@dynamic timestamp;
@dynamic tripID;
@dynamic verticalAccuracy;

@end
