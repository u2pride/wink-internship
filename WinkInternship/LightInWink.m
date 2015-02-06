//
//  LightInWink.m
//  WinkInternship
//
//  Created by Alex Ryan on 2/6/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import "LightInWink.h"

@implementation LightInWink

@synthesize lightID, lightManufacturer, lightName;

- (id) initWithLightID:(NSString *)lightIdentifier withLightName:(NSString *)name withManufacturer:(NSString *)manufacturer {
    
    self = [super init];
    if (self) {
        
        [self setLightID:lightIdentifier];
        [self setLightName:name];
        [self setLightManufacturer:manufacturer];
        
    }
    
    return self;
    
}


- (id) init {
    
    return [self initWithLightID:@"0000" withLightName:@"Light" withManufacturer:@"Wink"];
    
}

@end
