//
//  LightInWink.h
//  WinkInternship
//
//  Created by Alex Ryan on 2/6/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LightInWink : NSObject

@property (nonatomic, strong) NSString *lightID;
@property (nonatomic, strong) NSString *lightName;
@property (nonatomic, strong) NSString *lightManufacturer;

//Designated Initializer
- (id)initWithLightID:(NSString *)lightIdentifier
        withLightName: (NSString *)name
     withManufacturer:(NSString *)manufacturer;

- (id) init;

@end
