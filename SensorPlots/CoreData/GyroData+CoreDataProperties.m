//
//  GyroData+CoreDataProperties.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "GyroData+CoreDataProperties.h"

@implementation GyroData (CoreDataProperties)

@dynamic x;
@dynamic y;
@dynamic z;
@dynamic timestamp;
@dynamic timeInterval;
@dynamic avgValue;

@end
