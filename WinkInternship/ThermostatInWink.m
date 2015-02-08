//
//  ThermostatInWink.m
//  WinkInternship
//
//  Created by Alex Ryan on 2/6/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import "ThermostatInWink.h"

@implementation ThermostatInWink

@synthesize thermostatID, thermostatManufacturer, thermostatName;

- (id)initWithThermostatID:(NSString *)thermostatIdentifier withName:(NSString *)name withManufacturer:(NSString *)manufacturer {
    
    self = [super init];
    if (self) {
        
        [self setThermostatID:thermostatIdentifier];
        [self setThermostatName:name];
        [self setThermostatManufacturer:manufacturer];
        
    }
    
    return self;
    
}

- (id)init {
    
    return [self initWithThermostatID:@"0000" withName:@"Thermostat" withManufacturer:@"Wink"];
}

@end
