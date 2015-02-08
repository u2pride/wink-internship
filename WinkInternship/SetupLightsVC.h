//
//  SetupLightsVC.h
//  WinkInternship
//
//  Created by Alex Ryan on 2/5/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetupLightsVC : UIViewController <UITableViewDataSource, UITableViewDelegate>

//Thermostats Selected From Preview View Controller
@property (nonatomic, strong) NSMutableArray *selectedThermostats;

@end
