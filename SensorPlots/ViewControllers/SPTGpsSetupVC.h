//
//  SPTGpsSetupVC.h
//  SensorPlots
//
//  Created by Ajay Thakur on 3/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SPTGpsVCProtocol <NSObject>
@required
-(void)receiveGpsSetupData:(NSDictionary *)configuration;

@end

@interface SPTGpsSetupVC : UIViewController
@property (strong, nonatomic) id<SPTGpsVCProtocol>delegate;
@property (strong, nonatomic) NSMutableDictionary *configurationData;
@property (strong, nonatomic) NSNumber *countOfLocationPoints;
@end
