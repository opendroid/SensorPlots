//
//  LocationData+CoreDataProperties.h
//  SensorPlots
//
//  Created by Ajay Thakur on 12/25/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "LocationData+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface LocationData (CoreDataProperties)

+ (NSFetchRequest<LocationData *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *altitude;
@property (nullable, nonatomic, copy) NSNumber *course;
@property (nullable, nonatomic, copy) NSNumber *horizontalAccuracy;
@property (nullable, nonatomic, copy) NSNumber *latitude;
@property (nullable, nonatomic, copy) NSNumber *locationID;
@property (nullable, nonatomic, copy) NSNumber *longitude;
@property (nullable, nonatomic, copy) NSNumber *speed;
@property (nullable, nonatomic, copy) NSDate *timestamp;
@property (nullable, nonatomic, copy) NSNumber *tripID;
@property (nullable, nonatomic, copy) NSNumber *verticalAccuracy;

@end

NS_ASSUME_NONNULL_END
