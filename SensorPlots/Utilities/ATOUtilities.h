//
//  ATOUtilities.h
//  SensorPlots
//
//  Created by Ajay Thakur on 2/4/16.
//  Copyright © 2016 Ajay Thaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ATOUtilities : NSObject

+ (NSString *) createDataFilePathForName: (NSString *) fileName;
+ (void) showAppAlertWithMessage: (NSString *) message andViewController: (UIViewController *) vc;

@end
