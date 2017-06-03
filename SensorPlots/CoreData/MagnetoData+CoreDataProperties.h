//
//  MagnetoData+CoreDataProperties.h
//  SensorPlots
//
//  Created by Ajay Thakur on 12/25/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "MagnetoData+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MagnetoData (CoreDataProperties)

+ (NSFetchRequest<MagnetoData *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *avgValue;
@property (nullable, nonatomic, copy) NSNumber *sampleID;
@property (nullable, nonatomic, copy) NSNumber *testID;
@property (nullable, nonatomic, copy) NSNumber *timeInterval;
@property (nullable, nonatomic, copy) NSDate *timestamp;
@property (nullable, nonatomic, copy) NSNumber *x;
@property (nullable, nonatomic, copy) NSNumber *y;
@property (nullable, nonatomic, copy) NSNumber *z;

@end

NS_ASSUME_NONNULL_END
