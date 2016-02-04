//
//  AccelerometerData+CoreDataProperties.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/2/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "AccelerometerData.h"

NS_ASSUME_NONNULL_BEGIN

@interface AccelerometerData (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *x;
@property (nullable, nonatomic, retain) NSNumber *y;
@property (nullable, nonatomic, retain) NSNumber *z;
@property (nullable, nonatomic, retain) NSNumber *timeinterval;
@property (nullable, nonatomic, retain) NSNumber *gValue;
@property (nullable, nonatomic, retain) NSDate *timestamp;

@end

NS_ASSUME_NONNULL_END
