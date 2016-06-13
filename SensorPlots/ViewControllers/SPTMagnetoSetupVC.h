//
//  SPTMagnetoSetupVC.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SPTMagnetoVCProtocol <NSObject>
@required
-(void)receiveMagnetoRefreshRateHz:(NSNumber *)value;

@end

@interface SPTMagnetoSetupVC : UIViewController
@property (strong, nonatomic) id<SPTMagnetoVCProtocol>delegate;
@property (strong, nonatomic) NSNumber *refreshRateHz;
@property (strong, nonatomic) NSNumber *countOfTestDataValues;

@end
