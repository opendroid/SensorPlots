//
//  LocationData+CoreDataProperties.h
//  SensorPlots
//
//  Created by Ajay Thakur on 6/11/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "LocationData.h"

NS_ASSUME_NONNULL_BEGIN

@interface LocationData (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *latitude;
@property (nullable, nonatomic, retain) NSNumber *longitude;
@property (nullable, nonatomic, retain) NSNumber *altitude;
@property (nullable, nonatomic, retain) NSNumber *verticalAccuracy;
@property (nullable, nonatomic, retain) NSNumber *horizontalAccuracy;
@property (nullable, nonatomic, retain) NSNumber *course;
@property (nullable, nonatomic, retain) NSNumber *speed;
@property (nullable, nonatomic, retain) NSDate *timestamp;

@end

NS_ASSUME_NONNULL_END
