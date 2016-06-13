//
//  SPTAcclerometerRecordVC.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/5/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPTAcclerometerRecordVC : UIViewController

@property (strong, nonatomic) NSNumber * recordingIntervalHours;
@property (strong, nonatomic) NSString * recordingStatusMessage;

@end
