//
//  SPTGpsSetupVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 3/4/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "SPTGpsSetupVC.h"
#import "SPTConstants.h"

@import CoreLocation;
@import MapKit;

@interface SPTGpsSetupVC()
@property (weak, nonatomic) IBOutlet UILabel *updateMetersUIL;
@property (weak, nonatomic) IBOutlet UILabel *accuracyUIL;
@property (weak, nonatomic) IBOutlet UILabel *activityUIL;
@property (weak, nonatomic) IBOutlet UISwitch *backgroundModeUIS;
@property (weak, nonatomic) IBOutlet UISlider *distanceFilterUIS;
@property (weak, nonatomic) IBOutlet UISlider *accuracyTypeUIS;
@property (weak, nonatomic) IBOutlet UISlider *activityTypeUIS;
@property (weak, nonatomic) IBOutlet UIButton *enableLocationAccessUIB;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mapViewTypeUSC;
@property (weak, nonatomic) IBOutlet UILabel *displyLocationsCountInCoreDataUIL;

@end


@implementation SPTGpsSetupVC

- (void)viewDidLoad {
    [super viewDidLoad];

    // Update the UX
    [self initUXWithLastKnownConfig];
}

- (void) initUXWithLastKnownConfig {
    // Set background mode
    BOOL isOn = [[self.configurationData objectForKey:kATGpsIsBackgroundOnKey] boolValue];
    self.backgroundModeUIS.on = isOn;
    
    // Update Rate
    double filterValue = [[self.configurationData objectForKey:kATGpsUpdateKey] doubleValue];
    self.distanceFilterUIS.value = filterValue;
    self.updateMetersUIL.text = [self.configurationData objectForKey:kATGpsUpdateUILKey];
    
    // Accuracy
    double accuracyValue = [[self.configurationData objectForKey:kATGpsAccuracyUISKey] doubleValue];
    self.accuracyTypeUIS.value = accuracyValue;
    self.accuracyUIL.text = [self.configurationData objectForKey:kATGpsAccuracyUILKey];
    
    // Activity type
    double activityValue = [[self.configurationData objectForKey:kATGpsActivityUISKey] doubleValue];
    self.activityTypeUIS.value = activityValue;
    self.activityUIL.text = [self.configurationData objectForKey:kATGpsActivityUILKey];
    
    // Set Maptype
    MKMapType mapType = [[self.configurationData objectForKey:kATMapTypeConfigKey] integerValue];
    switch (mapType) {
        case MKMapTypeStandard:
            self.mapViewTypeUSC.selectedSegmentIndex = 0;
            break;
        case MKMapTypeSatellite:
            self.mapViewTypeUSC.selectedSegmentIndex = 1;
            break;
        case MKMapTypeHybrid:
            self.mapViewTypeUSC.selectedSegmentIndex = 2;
            break;
        case MKMapTypeSatelliteFlyover:
            self.mapViewTypeUSC.selectedSegmentIndex = 3;
            break;
        case MKMapTypeHybridFlyover:
            self.mapViewTypeUSC.selectedSegmentIndex = 4;
            break;
        default:
            self.mapViewTypeUSC.selectedSegmentIndex = 0;
            break;
    }
    
    //  Display Number of GPS data points
    self.displyLocationsCountInCoreDataUIL.text = [NSString stringWithFormat:@"%@ Saved locations", self.countOfLocationPoints];
}

- (IBAction)enableBackgroundModeHandler:(UISwitch *)sender {
    NSNumber *isOn = [NSNumber numberWithBool:self.backgroundModeUIS.isOn];
    [self.configurationData setObject:isOn forKey:kATGpsIsBackgroundOnKey];
    // Pass back to VC
    if(self.delegate && [self.delegate respondsToSelector:@selector(receiveGpsSetupData:)]) {
        [self.delegate receiveGpsSetupData:self.configurationData];
    }
}

- (IBAction)distanceFilterHandler:(UISlider *)sender {
    NSString *updateString = [NSString stringWithFormat:@"%.1f Mts",self.distanceFilterUIS.value];
    self.updateMetersUIL.text = updateString;
    NSNumber *updateValue = [NSNumber numberWithDouble:self.distanceFilterUIS.value];
    
    // Change config data.
    [self.configurationData setObject:updateValue forKey:kATGpsUpdateKey];
    [self.configurationData setObject:updateString forKey:kATGpsUpdateUILKey];
    // Pass back to VC
    if(self.delegate && [self.delegate respondsToSelector:@selector(receiveGpsSetupData:)]) {
        [self.delegate receiveGpsSetupData:self.configurationData];
    }
}

- (IBAction)accuracyTypeHandler:(UISlider *)sender {
    NSNumber *accuracyType;
    NSString *accuracyTypeText;
    self.updateMetersUIL.text = [NSString stringWithFormat:@"%.1f Mts",self.distanceFilterUIS.value];
    if (self.accuracyTypeUIS.value < 1.0) {
        accuracyType = [NSNumber numberWithDouble:kCLLocationAccuracyBestForNavigation];
        self.accuracyUIL.text = @"Navigation";
        accuracyTypeText = @"Navigation";
    } else if (self.accuracyTypeUIS.value < 2.0) {
        accuracyType = [NSNumber numberWithDouble:kCLLocationAccuracyBest];
        self.accuracyUIL.text = @"Best";
        accuracyTypeText = @"Best";
    } else if (self.accuracyTypeUIS.value < 3.0) {
        accuracyType = [NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters];
        self.accuracyUIL.text = @"10 Mts";
        accuracyTypeText = @"10 Mts";
    } else if (self.accuracyTypeUIS.value < 4.0) {
        accuracyType = [NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters];
        self.accuracyUIL.text = @"100 Mts";
        accuracyTypeText = @"100 Mts";
    } else if (self.accuracyTypeUIS.value < 5.0) {
        accuracyType = [NSNumber numberWithDouble:kCLLocationAccuracyKilometer];
        self.accuracyUIL.text = @"1000 Mts";
        accuracyTypeText = @"1000 Mts";
    } else {
        accuracyType = [NSNumber numberWithDouble:kCLLocationAccuracyThreeKilometers];
        self.accuracyUIL.text = @"3000 Mts";
        accuracyTypeText = @"3000 Mts";
    }
    NSNumber *accuracyUISValue = [NSNumber numberWithDouble:self.accuracyTypeUIS.value];
    
    // Change config data.
    [self.configurationData setObject:accuracyType forKey:kATGpsAccuracyKey];
    [self.configurationData setObject:accuracyUISValue forKey:kATGpsAccuracyUISKey];
    [self.configurationData setObject:accuracyTypeText forKey:kATGpsAccuracyUILKey];
    
    // Pass back to VC
    if(self.delegate && [self.delegate respondsToSelector:@selector(receiveGpsSetupData:)]) {
        [self.delegate receiveGpsSetupData:self.configurationData];
    }
}

- (IBAction)activityTypeHandler:(UISlider *)sender {
    NSNumber *activityType;
    NSString *activityTypeText;
    
    if (self.activityTypeUIS.value < 2.0) {
        activityType = [NSNumber numberWithInteger:CLActivityTypeOther];
        self.activityUIL.text = @"Other";
        activityTypeText =  @"Other";
    } else if (self.activityTypeUIS.value < 3.0) {
        activityType = [NSNumber numberWithInteger:CLActivityTypeAutomotiveNavigation];
        self.activityUIL.text = @"Auto Navigation";
        activityTypeText =  @"Auto Navigation";
    } else if (self.activityTypeUIS.value < 4.0) {
        activityType = [NSNumber numberWithInteger:CLActivityTypeFitness];
        self.activityUIL.text = @"Fitness";
        activityTypeText =  @"Fitness";
    } else {
        activityType = [NSNumber numberWithInteger:CLActivityTypeOtherNavigation];
        self.activityUIL.text = @"Other Navigation";
        activityTypeText =  @"Other Navigation";
    }
    NSNumber *activityUISValue = [NSNumber numberWithDouble:self.activityTypeUIS.value];
    
    // Change config data.
    [self.configurationData setObject:activityType forKey:kATGpsActivityKey];
    [self.configurationData setObject:activityUISValue forKey:kATGpsActivityUISKey];
    [self.configurationData setObject:activityTypeText forKey:kATGpsActivityUILKey];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(receiveGpsSetupData:)]) {
        [self.delegate receiveGpsSetupData:self.configurationData];
    }
}

// Open the App settings page.
- (IBAction)locationAccessHandler:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

// Setup map type
- (IBAction)mapViewTypeHandler:(UISegmentedControl *)sender {
    MKMapType mapType;
    switch (sender.selectedSegmentIndex) {
        case 0:
            mapType = MKMapTypeStandard;
            break;
        case 1:
            mapType = MKMapTypeSatellite;
            break;
        case 2:
            mapType = MKMapTypeHybrid;
            break;
        case 3:
            mapType = MKMapTypeSatelliteFlyover; // For future
            break;
        case 4:
        default:
            mapType = MKMapTypeHybridFlyover; // For future
            break;
    }
    
    // communicate info to GPS VC
    NSNumber *mapTypeValue = [NSNumber numberWithInteger:mapType];
    [self.configurationData setObject:mapTypeValue forKey:kATMapTypeConfigKey];
    if(self.delegate && [self.delegate respondsToSelector:@selector(receiveGpsSetupData:)]) {
        [self.delegate receiveGpsSetupData:self.configurationData];
    }
    
}


@end
