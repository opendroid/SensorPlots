//
//  LocationSummary+CoreDataProperties.h
//  SensorPlots
//
//  Created by Ajay Thakur on 12/25/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "LocationSummary+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface LocationSummary (CoreDataProperties)

+ (NSFetchRequest<LocationSummary *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *averageSpeed;
@property (nullable, nonatomic, copy) NSNumber *distanceMeters;
@property (nullable, nonatomic, copy) NSDate *endTime;
@property (nullable, nonatomic, copy) NSNumber *isProcessed;
@property (nullable, nonatomic, copy) NSNumber *maxSpeed;
@property (nullable, nonatomic, copy) NSDecimalNumber *minSpeed;
@property (nullable, nonatomic, copy) NSNumber *nSamples;
@property (nullable, nonatomic, copy) NSDate *startTime;
@property (nullable, nonatomic, copy) NSNumber *testID;
@property (nullable, nonatomic, copy) NSNumber *testType;

@end

NS_ASSUME_NONNULL_END
