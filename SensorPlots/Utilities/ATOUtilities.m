//
//  ATOUtilities.m
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import "ATOUtilities.h"

@implementation ATOUtilities

+ (NSString *) createDataFilePathForName: (NSString *) fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fullPathFileName = [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
    return fullPathFileName;
}

#pragma mark - Utility methods
// Show 'showAppAlertWithMessage' a utility to show a alert message
+ (void) showAppAlertWithMessage: (NSString *) message
               andViewController: (UIViewController *) vc {
    UIAlertController *okVC = [UIAlertController alertControllerWithTitle:@"Sensor Plots" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [okVC addAction:okAction];
    [vc presentViewController:okVC animated:YES completion:nil];
}

@end
