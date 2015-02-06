//
//  BrandOfWink.m
//  WinkInternship
//
//  Created by Alex Ryan on 2/5/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import "BrandOfWink.h"

@implementation BrandOfWink

@synthesize nameOfBrand, brandImage, manufacturerName;

- (id) initWithBrandName: (NSString *)name withBrandImage: (UIImage *)image withManufacturer:(NSString *)manufacturer {
    
    self = [super init];
    if (self) {
        
        [self setNameOfBrand:name];
        [self setBrandImage:image];
        [self setManufacturerName:manufacturer];
    }
    
    return self;
}


- (id) init {
    
    return [self initWithBrandName:@"Wink" withBrandImage:[UIImage imageNamed:@"Wink"] withManufacturer:@"Wink"];
}

@end
