//
//  ThermostatInWink.h
//  WinkInternship
//
//  Created by Alex Ryan on 2/6/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThermostatInWink : NSObject

@property (nonatomic, strong) NSString *thermostatID;
@property (nonatomic, strong) NSString *thermostatName;
@property (nonatomic, strong) NSString *thermostatManufacturer;

//Designated Initializer
- (id)initWithThermostatID:(NSString *)thermostatIdentifier
                  withName:(NSString *)name
          withManufacturer:(NSString *)manufacturer;

- (id) init;

@end