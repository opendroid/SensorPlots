//
//  SPTAccelerometerSetupVC.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/2/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SPTAccelerometerVCProtocol <NSObject>
@required
-(void)receiveAccelerometerRefreshRateHz:(NSNumber *)value;
-(void)receiveAccelerometerBackgroundConfig:(BOOL)value;

@end

@interface SPTAccelerometerSetupVC : UIViewController

@property (strong, nonatomic) id<SPTAccelerometerVCProtocol>delegate;
@property (strong, nonatomic) NSNumber *refreshRateHz;
@property (nonatomic) BOOL    isEnabled;
@property (strong, nonatomic) NSNumber *countOfTestDataValues;

@end
