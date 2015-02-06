//
//  ControlRobotVC.h
//  WinkInternship
//
//  Created by Alex Ryan on 2/5/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ControlRobotVC : UIViewController

@property (nonatomic, strong) NSArray *userLights;
@property (nonatomic, strong) NSArray *userThermostats;

- (IBAction)startLightCorrection:(id)sender;

@end
