//
//  SPTGyroSetupVC.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SPTGyroVCProtocol <NSObject>
@required
-(void)receiveGyroRefreshRateHz:(NSNumber *)value;
-(void)receiveGyroBackgroundConfig:(BOOL)value;

@end

@interface SPTGyroSetupVC : UIViewController
@property (strong, nonatomic) id<SPTGyroVCProtocol>delegate;
@property (strong, nonatomic) NSNumber *refreshRateHz;
@property (strong, nonatomic) NSNumber *countOfTestDataValues;
@property (nonatomic) BOOL    isEnabled;

@end
