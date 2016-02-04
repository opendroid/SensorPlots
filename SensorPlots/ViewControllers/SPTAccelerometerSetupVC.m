//
//  SPTAccelerometerSetupVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/2/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "AppDelegate.h"
#import "SPTAccelerometerSetupVC.h"
#import "AccelerometerData.h"
@interface SPTAccelerometerSetupVC()
@property (weak, nonatomic) IBOutlet UISlider *refreshRateHzUIS;
@property (weak, nonatomic) IBOutlet UILabel *refreshRateHzUIL;
@property (weak, nonatomic) IBOutlet UILabel *coreDataCountUIL;

@end

@implementation SPTAccelerometerSetupVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set up the UX
    self.refreshRateHzUIS.value = self.refreshRateHz.floatValue;
    self.refreshRateHzUIL.text = [NSString stringWithFormat:@"%3.0f Hz",self.refreshRateHz.floatValue];
    self.coreDataCountUIL.text = [NSString stringWithFormat:@"%.lu stored data points.",self.countOfTestDataValues.integerValue];
}

- (IBAction)refreshRateHzHandler:(UISlider *)sender {
    self.refreshRateHzUIL.text = [NSString stringWithFormat:@"%3.0f Hz",self.refreshRateHzUIS.value];
    
    // Setup the handler.
    if (self.refreshRateHzUIS.value <= 1.0) {
        self.refreshRateHzUIS.value = 1.0;
    } else if (self.refreshRateHzUIS.value >= 100) {
        self.refreshRateHzUIS.value = 100.0;
    }
    
    if(self.delegate) {
        [self.delegate receiveAcceleratorRefreshRateHz:[NSNumber numberWithFloat:self.refreshRateHzUIS.value]];
    }
}

@end
