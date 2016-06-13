//
//  SPTAcclerometerRecordVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/5/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "SPTAcclerometerRecordVC.h"

@interface SPTAcclerometerRecordVC()
@property (weak, nonatomic) IBOutlet UILabel *recordIntervalDisplayUIL;
@property (weak, nonatomic) IBOutlet UISlider *recordIntervalTimeUIS;
@property (weak, nonatomic) IBOutlet UILabel *displayBoardUIL;
@property (weak, nonatomic) IBOutlet UIButton *recordCommandUIB;



@end

@implementation SPTAcclerometerRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (! self.recordingIntervalHours) {
        self.recordingIntervalHours = [NSNumber numberWithFloat:2.0];
    }
    self.recordIntervalTimeUIS.value = self.recordingIntervalHours.doubleValue;
    self.recordIntervalDisplayUIL.text = [NSString stringWithFormat:@"%.2f Hours", self.recordingIntervalHours.floatValue];
    
    if (!self.recordingStatusMessage) {
        self.displayBoardUIL.text = @"You can record for 12 hours.";
    } else {
        self.displayBoardUIL.text = self.recordingStatusMessage;
    }
}

- (IBAction)recordIntervalValeHandler:(UISlider *)sender {
    if (sender.value < 0.4)
        sender.value = 0.4;
    self.recordingIntervalHours = [NSNumber numberWithFloat:sender.value];
    self.recordIntervalDisplayUIL.text = [NSString stringWithFormat:@"%.2f Hours", self.recordingIntervalHours.floatValue];
}

@end
