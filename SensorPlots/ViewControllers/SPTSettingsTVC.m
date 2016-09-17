//
//  SPTSettingsTVC.m
//  SensorPlots
//
//  Created by Ajay Thakur on 8/13/16.
//  Copyright © 2016 Ajay Thakur. All rights reserved.
//

#import "SPTSettingsTVC.h"
#import "SPTConstants.h"
#import "ATOUtilities.h"
@import MapKit;

@interface SPTSettingsTVC ()

// Accelerometer settings controls
@property (weak, nonatomic) IBOutlet UISlider *acceleroRefreshRateHzUIS;
@property (weak, nonatomic) IBOutlet UILabel *acceleroRefreshRateHzUIL;
@property (weak, nonatomic) IBOutlet UISwitch *acceleroBackgroundUIS;
@property (weak, nonatomic) IBOutlet UILabel *acceleroCoreDataCountUIL;

// Gyro settings controls
@property (weak, nonatomic) IBOutlet UISlider *gyroRefreshRateHzUIS;
@property (weak, nonatomic) IBOutlet UILabel *gyroRefreshRateHzUIL;
@property (weak, nonatomic) IBOutlet UISwitch *gyroBackgroundUIS;
@property (weak, nonatomic) IBOutlet UILabel *gyroCoreDataCountUIL;

// Magneto settings controls
@property (weak, nonatomic) IBOutlet UISlider *magnetoRefreshRateHzUIS;
@property (weak, nonatomic) IBOutlet UILabel *magnetoRefreshRateHzUIL;
@property (weak, nonatomic) IBOutlet UISwitch *magnetoBackgroundUIS;
@property (weak, nonatomic) IBOutlet UILabel *magnetoCoreDataCountUIL;

// GPS settings controls
@property (weak, nonatomic) IBOutlet UISlider *gpsDistanceFilterUIS;
@property (weak, nonatomic) IBOutlet UILabel *gpsDistanceFilterUIL;
@property (weak, nonatomic) IBOutlet UISlider *gpsAccuracyFilterUIS;
@property (weak, nonatomic) IBOutlet UILabel *gpsAccuracyFilterUIL;
@property (weak, nonatomic) IBOutlet UISegmentedControl *gpsActivityUIS;
@property (weak, nonatomic) IBOutlet UISegmentedControl *gpsMapTypeUIS;
@property (weak, nonatomic) IBOutlet UISwitch *gpsBackgroundUIS;
@property (weak, nonatomic) IBOutlet UILabel *gpsCoreDataCountUIL;
@property (strong, nonatomic) NSMutableDictionary *gpsConfigurationData;


@end

@implementation SPTSettingsTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self initSettingsUX];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    NSLog(@"Settings:tabBarController");
}

// Retrieve data from NSUserDefaults and show values in the Setup Interface elements
- (void) initSettingsUX {
    // Setup Accelerometer
    NSNumber *refreshRate = [ATOUtilities getAccelerometerConfigurationFromNSU];
    if (refreshRate != NULL) {
        [self setupAcceleroUISlider:refreshRate.floatValue];
    }
    [self initAcceleroSettingsUI];
    BOOL backgroundMode = [ATOUtilities getAccelerometerBackgroundMode];
    [self.acceleroBackgroundUIS setOn:backgroundMode animated:NO];
    self.acceleroCoreDataCountUIL.text = [ATOUtilities savedCountOfAcceleroDataPoints].stringValue;
    
    // Setup Gyro
    refreshRate = [ATOUtilities getGyroConfigurationFromNSU];
    if (refreshRate != NULL) {
        [self setupGyroUISlider:refreshRate.floatValue];
    }
    [self initGyroSettingsUI];
    backgroundMode = [ATOUtilities getGyroBackgroundMode];
    [self.gyroBackgroundUIS setOn:backgroundMode animated:NO];
    self.gyroCoreDataCountUIL.text = [ATOUtilities savedCountOfGyroDataPoints].stringValue;
    
    // Setup Magneto
    refreshRate = [ATOUtilities getMagnetoConfigurationFromNSU];
    if (refreshRate != NULL) {
        [self setupMagnetoUISlider:refreshRate.floatValue];
    }
    [self initMagnetoSettingsUI];
    backgroundMode = [ATOUtilities getMagnetoBackgroundMode];
    [self.magnetoBackgroundUIS setOn:backgroundMode animated:NO];
    self.magnetoCoreDataCountUIL.text = [ATOUtilities savedCountOfMagnetoDataPoints].stringValue;
    
    // Setup GPS.
    self.gpsConfigurationData = [[ATOUtilities getGpsConfigurationFromNSU] mutableCopy];
    [self initGpsSettingsUI];
    
}

#pragma mark - Accelero Settings Handlers
//
// Accelero Settings UX Handline
//
-(void) initAcceleroSettingsUI {
    self.acceleroRefreshRateHzUIL.text = [NSString stringWithFormat:@"%.0f Hz", self.acceleroRefreshRateHzUIS.value];
}

- (void) setupAcceleroUISlider: (float) value{
    // Setup sloder color
    //self.acceleroRefreshRateHzUIS.value = self.refreshRateHz.intValue;
    // Setup the handler.
    if (value <= 1.0) {
        value = 1.0;
    } else if (value >= 100) {
        value = 100.0;
    }
    
    NSNumber *newRefreshRate = [NSNumber numberWithInt:(int)ceilf(value)];
    self.acceleroRefreshRateHzUIS.value = newRefreshRate.intValue;
    self.acceleroRefreshRateHzUIL.text = [NSString stringWithFormat:@"%d Hz",newRefreshRate.intValue];
    if (self.acceleroRefreshRateHzUIS.value > 66.0) {
        UIColor *customRed = [UIColor colorWithRed:0xdf/255.0 green:1.0/255.0 blue:0x3a/255.0 alpha:1.0];
        self.acceleroRefreshRateHzUIS.tintColor = customRed;
        self.acceleroRefreshRateHzUIS.thumbTintColor = customRed;
        self.acceleroRefreshRateHzUIL.textColor = customRed;
    } else if (self.acceleroRefreshRateHzUIS.value > 33.0){
        UIColor *lightBlue = [UIColor colorWithRed:0 green:122.0/255.0 blue:1.0 alpha:1.0];
        self.acceleroRefreshRateHzUIS.tintColor = lightBlue;
        self.acceleroRefreshRateHzUIS.thumbTintColor = lightBlue;
        self.acceleroRefreshRateHzUIL.textColor = lightBlue;
    } else {
        UIColor *customGreen = [UIColor colorWithRed:0x31/255 green:0xB4/255.0 blue:0x04/255.0 alpha:1.0];
        self.acceleroRefreshRateHzUIS.tintColor = customGreen;
        self.acceleroRefreshRateHzUIS.thumbTintColor = customGreen;
        self.acceleroRefreshRateHzUIL.textColor = customGreen;
    }
    [[NSUserDefaults standardUserDefaults] setObject:newRefreshRate forKey:@"SPTAccelerometerHzSetting"];
}


- (IBAction)acceleroRefreshRateHzHandler:(UISlider *)sender {
    [self setupAcceleroUISlider:self.acceleroRefreshRateHzUIS.value];
}

- (IBAction)acceleroBackgroundModeHandler:(UISwitch *)sender {
    BOOL isOn = self.acceleroBackgroundUIS.isOn;
    [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:kATAcceleroBackgroundConfigKey];
}


#pragma mark - Gyro Settings Handlers
//
// Gyro Settings UX Handling
//
-(void) initGyroSettingsUI {
    self.gyroRefreshRateHzUIL.text = [NSString stringWithFormat:@"%.0f Hz", self.gyroRefreshRateHzUIS.value];
}

- (void) setupGyroUISlider: (float) value{
    // Setup sloder color
    //self.acceleroRefreshRateHzUIS.value = self.refreshRateHz.intValue;
    // Setup the handler.
    if (value <= 1.0) {
        value = 1.0;
    } else if (value >= 100) {
        value = 100.0;
    }
    
    NSNumber *newRefreshRate = [NSNumber numberWithInt:(int)ceilf(value)];
    
    self.gyroRefreshRateHzUIS.value = newRefreshRate.intValue;
    self.gyroRefreshRateHzUIL.text = [NSString stringWithFormat:@"%d Hz",newRefreshRate.intValue];
    if (self.gyroRefreshRateHzUIS.value > 66.0) {
        UIColor *customRed = [UIColor colorWithRed:0xdf/255.0 green:1.0/255.0 blue:0x3a/255.0 alpha:1.0];
        self.gyroRefreshRateHzUIS.tintColor = customRed;
        self.gyroRefreshRateHzUIS.thumbTintColor = customRed;
        self.gyroRefreshRateHzUIL.textColor = customRed;
    } else if (self.gyroRefreshRateHzUIS.value > 33.0){
        UIColor *lightBlue = [UIColor colorWithRed:0 green:122.0/255.0 blue:1.0 alpha:1.0];
        self.gyroRefreshRateHzUIS.tintColor = lightBlue;
        self.gyroRefreshRateHzUIS.thumbTintColor = lightBlue;
        self.gyroRefreshRateHzUIL.textColor = lightBlue;
    } else {
        UIColor *customGreen = [UIColor colorWithRed:0x31/255 green:0xB4/255.0 blue:0x04/255.0 alpha:1.0];
        self.gyroRefreshRateHzUIS.tintColor = customGreen;
        self.gyroRefreshRateHzUIS.thumbTintColor = customGreen;
        self.gyroRefreshRateHzUIL.textColor = customGreen;
    }
    [[NSUserDefaults standardUserDefaults] setObject:newRefreshRate forKey:@"SPTGyroHzSetting"];
}
- (IBAction)gyroRefreshRateHzHandler:(UISlider *)sender {
    [self setupGyroUISlider:self.gyroRefreshRateHzUIS.value];
}

- (IBAction)gyroBackgroundModeHandler:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:self.gyroBackgroundUIS.isOn forKey:kATGyroBackgroundConfigKey];
}

#pragma mark - Magneto Settings Handlers
//
// Magneto Settings UX Handling
//
-(void) initMagnetoSettingsUI {
    self.magnetoRefreshRateHzUIL.text = [NSString stringWithFormat:@"%.0f Hz", self.magnetoRefreshRateHzUIS.value];
}

- (void) setupMagnetoUISlider: (float) value{
    // Setup sloder color
    //self.acceleroRefreshRateHzUIS.value = self.refreshRateHz.intValue;
    // Setup the handler.
    if (value <= 1.0) {
        value = 1.0;
    } else if (value >= 100) {
        value = 100.0;
    }
    
    NSNumber *newRefreshRate = [NSNumber numberWithInt:(int)ceilf(value)];
    self.magnetoRefreshRateHzUIS.value = newRefreshRate.intValue;
    self.magnetoRefreshRateHzUIL.text = [NSString stringWithFormat:@"%d Hz",newRefreshRate.intValue];
    if (self.magnetoRefreshRateHzUIS.value > 66.0) {
        UIColor *customRed = [UIColor colorWithRed:0xdf/255.0 green:1.0/255.0 blue:0x3a/255.0 alpha:1.0];
        self.magnetoRefreshRateHzUIS.tintColor = customRed;
        self.magnetoRefreshRateHzUIS.thumbTintColor = customRed;
        self.magnetoRefreshRateHzUIL.textColor = customRed;
    } else if (self.magnetoRefreshRateHzUIS.value > 33.0){
        UIColor *lightBlue = [UIColor colorWithRed:0 green:122.0/255.0 blue:1.0 alpha:1.0];
        self.magnetoRefreshRateHzUIS.tintColor = lightBlue;
        self.magnetoRefreshRateHzUIS.thumbTintColor = lightBlue;
        self.magnetoRefreshRateHzUIL.textColor = lightBlue;
    } else {
        UIColor *customGreen = [UIColor colorWithRed:0x31/255 green:0xB4/255.0 blue:0x04/255.0 alpha:1.0];
        self.magnetoRefreshRateHzUIS.tintColor = customGreen;
        self.magnetoRefreshRateHzUIS.thumbTintColor = customGreen;
        self.magnetoRefreshRateHzUIL.textColor = customGreen;
    }
    [[NSUserDefaults standardUserDefaults] setObject:newRefreshRate forKey:@"SPTMagnetoHzSetting"];
}
- (IBAction)magnetoRefreshRateHzHandler:(UISlider *)sender {
    [self setupMagnetoUISlider:self.magnetoRefreshRateHzUIS.value];
}

- (IBAction)magnetoBackgroundModeHandler:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:self.magnetoBackgroundUIS.isOn forKey:kATMagnetoBackgroundConfigKey];
}

#pragma mark - GPS view data source
//
// GPS Settings UX Handling
//
- (void) initGpsSettingsUI {
    // 1: Setup Distance filter
    double distanceFilterValue = [[self.gpsConfigurationData objectForKey:kATGpsUpdateKey] doubleValue];
    self.gpsDistanceFilterUIS.value = distanceFilterValue;
    self.gpsDistanceFilterUIL.text = [self.gpsConfigurationData objectForKey:kATGpsUpdateUILKey];
    
    // 2: Setup Accuracy filter
    double accuracyValue = [[self.gpsConfigurationData objectForKey:kATGpsAccuracyUISKey] doubleValue];
    self.gpsAccuracyFilterUIS.value = accuracyValue;
    self.gpsAccuracyFilterUIL.text = [self.gpsConfigurationData objectForKey:kATGpsAccuracyUILKey];
    
    // 3: Setup Activity
    double activityValue = [[self.gpsConfigurationData objectForKey:kATGpsActivityUISKey] doubleValue];
    self.gpsActivityUIS.selectedSegmentIndex = activityValue;
    if (activityValue <= 1.0) {
        self.gpsActivityUIS.selectedSegmentIndex = 0;
    } else if (activityValue <= 2.0) {
        self.gpsActivityUIS.selectedSegmentIndex = 1;
    } else if (activityValue <= 3.0) {
        self.gpsActivityUIS.selectedSegmentIndex = 2;
    } else if (activityValue <= 4.0) {
        self.gpsActivityUIS.selectedSegmentIndex = 3;
    } else {
        self.gpsActivityUIS.selectedSegmentIndex = 4;
    }
    
    // 4: Set Maptype: only three are used. Others are for furture use.
    MKMapType mapType = [[self.gpsConfigurationData objectForKey:kATMapTypeConfigKey] integerValue];
    switch (mapType) {
        case MKMapTypeStandard:
            self.gpsMapTypeUIS.selectedSegmentIndex = 0;
            break;
        case MKMapTypeSatellite:
            self.gpsMapTypeUIS.selectedSegmentIndex = 1;
            break;
        case MKMapTypeHybrid:
            self.gpsMapTypeUIS.selectedSegmentIndex = 2;
            break;
        case MKMapTypeSatelliteFlyover:
            self.gpsMapTypeUIS.selectedSegmentIndex = 3;
            break;
        case MKMapTypeHybridFlyover:
            self.gpsMapTypeUIS.selectedSegmentIndex = 4;
            break;
        default:
            self.gpsMapTypeUIS.selectedSegmentIndex = 0;
            break;
    }
    
    // 5: Background mode.
    BOOL isOn = [[self.gpsConfigurationData objectForKey:kATGpsIsBackgroundOnKey] boolValue];
    self.gpsBackgroundUIS.on = isOn;
    
    // 6: Count of stored data points
    self.gpsCoreDataCountUIL.text = [ATOUtilities savedCountOfLocationDataPoints].stringValue;
}

- (IBAction)gpsDistanceFilterHandler:(UISlider *)sender {
    NSString *updateString = [NSString stringWithFormat:@"%.1f Mts",self.gpsDistanceFilterUIS.value];
    self.gpsDistanceFilterUIL.text = updateString;
    NSNumber *updateValue = [NSNumber numberWithDouble:self.gpsDistanceFilterUIS.value];
    
    // Change config data.
    [self.gpsConfigurationData setObject:updateValue forKey:kATGpsUpdateKey];
    [self.gpsConfigurationData setObject:updateString forKey:kATGpsUpdateUILKey];
    [ATOUtilities saveGpsConfig:self.gpsConfigurationData];
}

- (IBAction)gpsAccuracyFilterHandler:(UISlider *)sender {
    NSNumber *accuracyType;
    NSString *accuracyTypeText;
    if (self.gpsAccuracyFilterUIS.value < 1.0) {
        accuracyType = [NSNumber numberWithDouble:kCLLocationAccuracyBestForNavigation];
        self.gpsAccuracyFilterUIL.text = @"Navigation";
        accuracyTypeText = @"Navigation";
    } else if (self.gpsAccuracyFilterUIS.value < 2.0) {
        accuracyType = [NSNumber numberWithDouble:kCLLocationAccuracyBest];
        self.gpsAccuracyFilterUIL.text = @"Best";
        accuracyTypeText = @"Best";
    } else if (self.gpsAccuracyFilterUIS.value < 3.0) {
        accuracyType = [NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters];
        self.gpsAccuracyFilterUIL.text = @"10 Mts";
        accuracyTypeText = @"10 Mts";
    } else if (self.gpsAccuracyFilterUIS.value < 4.0) {
        accuracyType = [NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters];
        self.gpsAccuracyFilterUIL.text = @"100 Mts";
        accuracyTypeText = @"100 Mts";
    } else if (self.gpsAccuracyFilterUIS.value < 5.0) {
        accuracyType = [NSNumber numberWithDouble:kCLLocationAccuracyKilometer];
        self.gpsAccuracyFilterUIL.text = @"1000 Mts";
        accuracyTypeText = @"1000 Mts";
    } else {
        accuracyType = [NSNumber numberWithDouble:kCLLocationAccuracyThreeKilometers];
        self.gpsAccuracyFilterUIL.text = @"3000 Mts";
        accuracyTypeText = @"3000 Mts";
    }
    NSNumber *accuracyUISValue = [NSNumber numberWithDouble:self.gpsAccuracyFilterUIS.value];
    
    // Change config data.
    [self.gpsConfigurationData setObject:accuracyType forKey:kATGpsAccuracyKey];
    [self.gpsConfigurationData setObject:accuracyUISValue forKey:kATGpsAccuracyUISKey];
    [self.gpsConfigurationData setObject:accuracyTypeText forKey:kATGpsAccuracyUILKey];
    [ATOUtilities saveGpsConfig:self.gpsConfigurationData];
}

- (IBAction)gpsActivityTypeHandler:(UISegmentedControl *)sender {
    // Save the data in the NSUserDefaults
    NSNumber *activityType;
    switch (self.gpsActivityUIS.selectedSegmentIndex) {
        case 0:
            activityType = [NSNumber numberWithInteger:CLActivityTypeOther];
            break;
        case 1:
            activityType = [NSNumber numberWithInteger:CLActivityTypeAutomotiveNavigation];
            break;
        case 3:
            activityType = [NSNumber numberWithInteger:CLActivityTypeFitness];
            break;
        case 4:
        default:
            activityType = [NSNumber numberWithInteger:CLActivityTypeOtherNavigation];
    }
    NSNumber *activityUISValue = [NSNumber numberWithDouble:self.gpsActivityUIS.selectedSegmentIndex];
    
    // Change config data.
    [self.gpsConfigurationData setObject:activityType forKey:kATGpsActivityKey];
    [self.gpsConfigurationData setObject:activityUISValue forKey:kATGpsActivityUISKey];
    [ATOUtilities saveGpsConfig:self.gpsConfigurationData];
}

- (IBAction)gpsMapTypeHandler:(UISegmentedControl *)sender {
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
    [self.gpsConfigurationData setObject:mapTypeValue forKey:kATMapTypeConfigKey];
    [ATOUtilities saveGpsConfig:self.gpsConfigurationData];
}

- (IBAction)gpsBackgroundModeHandler:(UISwitch *)sender {
    NSNumber *isOn = [NSNumber numberWithBool:self.gpsBackgroundUIS.isOn];
    [self.gpsConfigurationData setObject:isOn forKey:kATGpsIsBackgroundOnKey];
    [ATOUtilities saveGpsConfig:self.gpsConfigurationData];
}


#pragma mark - Table 
// Manage the tapping on System Setting row.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%@, Section:%ld, Row:%ld", indexPath,(long)indexPath.section,(long)indexPath.row);
    if (indexPath.section == 4 && indexPath.row == 0 && IS_OS_8_OR_LATER) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL:settingsURL];
        NSLog(@"Can open URL: %d %@",canOpenURL, settingsURL);
        if (canOpenURL) {
            @try {
                [[UIApplication sharedApplication] openURL:settingsURL];
            } @catch (NSException *exception) {
                [ATOUtilities showAppAlertWithMessage:@"Enable location settings first" andViewController:self];
            } @finally {
                ;
            }
        }
    }
}

@end
