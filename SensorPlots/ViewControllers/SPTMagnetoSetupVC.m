//
//  SPTMagnetoSetupVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "SPTMagnetoSetupVC.h"

@interface SPTMagnetoSetupVC()
@property (weak, nonatomic) IBOutlet UISlider *refreshRateHzUIS;
@property (weak, nonatomic) IBOutlet UILabel *refreshRateHzUIL;
@property (weak, nonatomic) IBOutlet UILabel *coreDataCountUIL;
@property (weak, nonatomic) IBOutlet UISwitch *backgroundUIS;

@end

@implementation SPTMagnetoSetupVC
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set up the UX
    [self setupUISlider];
    self.refreshRateHzUIL.text = [NSString stringWithFormat:@"%d Hz",self.refreshRateHz.intValue];
    self.coreDataCountUIL.text = [NSString stringWithFormat:@"%.lu stored data points.",(long)self.countOfTestDataValues.integerValue];
    
    self.backgroundUIS.on = self.isEnabled;
}

- (IBAction)refreshRateHzHandler:(UISlider *)sender {
    // Setup the handler.
    float value = self.refreshRateHzUIS.value;
    if (value <= 1.0) {
        value = 1.0;
    } else if (value >= 100) {
        value = 100.0;
    }
    
    NSNumber *newRefreshRate = [NSNumber numberWithInt:(int)ceilf(value)];
    self.refreshRateHz = newRefreshRate;
    self.refreshRateHzUIL.text = [NSString stringWithFormat:@"%d Hz",newRefreshRate.intValue];
    [self setupUISlider];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(receiveMagnetoRefreshRateHz:)]) {
        [self.delegate receiveMagnetoRefreshRateHz:newRefreshRate];
    }
}

- (void) setupUISlider{
    // Setup sloder color
    self.refreshRateHzUIS.value = self.refreshRateHz.intValue;
    
    if (self.refreshRateHzUIS.value > 70.0) {
        UIColor *customRed = [UIColor colorWithRed:0xdf/255.0 green:1.0/255.0 blue:0x3a/255.0 alpha:1.0];
        self.refreshRateHzUIS.tintColor = customRed;
        self.refreshRateHzUIS.thumbTintColor = customRed;
        self.refreshRateHzUIL.textColor = customRed;
    } else if (self.refreshRateHzUIS.value > 30.0){
        UIColor *lightBlue = [UIColor colorWithRed:0 green:122.0/255.0 blue:1.0 alpha:1.0];
        self.refreshRateHzUIS.tintColor = lightBlue;
        self.refreshRateHzUIS.thumbTintColor = lightBlue;
        self.refreshRateHzUIL.textColor = lightBlue;
    } else {
        UIColor *customGreen = [UIColor colorWithRed:0x31/255 green:0xB4/255.0 blue:0x04/255.0 alpha:1.0];
        self.refreshRateHzUIS.tintColor = customGreen;
        self.refreshRateHzUIS.thumbTintColor = customGreen;
        self.refreshRateHzUIL.textColor = customGreen;
    }
}
- (IBAction)backgroundHandler:(UISwitch *)sender {
    // receiveAccelerometerBackgroundConfig
    if(self.delegate && [self.delegate respondsToSelector:@selector(receiveMagnetoBackgroundConfig:)]) {
        [self.delegate receiveMagnetoBackgroundConfig:sender.isOn];
    }
}

@end
