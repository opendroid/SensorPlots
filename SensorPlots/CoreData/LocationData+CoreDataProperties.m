//
//  LocationData+CoreDataProperties.m
//  SensorPlots
//
//  Created by Ajay Thakur on 6/11/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "LocationData+CoreDataProperties.h"

@implementation LocationData (CoreDataProperties)

@dynamic latitude;
@dynamic longitude;
@dynamic altitude;
@dynamic verticalAccuracy;
@dynamic horizontalAccuracy;
@dynamic course;
@dynamic speed;
@dynamic timestamp;

@end
