//
//  AccelerometerData+CoreDataClass.h
//  SensorPlots
//
//  Created by Ajay Thakur on 12/25/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface AccelerometerData : NSManagedObject
// Insert code here to declare functionality of your managed object subclass
- (NSNumber *) avgValue;
- (NSDate *) timestamp;
@end

NS_ASSUME_NONNULL_END

#import "AccelerometerData+CoreDataProperties.h"
