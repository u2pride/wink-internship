//
//  BrandOfWink.h
//  WinkInternship
//
//  Created by Alex Ryan on 2/5/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BrandOfWink : NSObject

@property (nonatomic, strong) NSString *nameOfBrand;
@property (nonatomic, strong) UIImage *brandImage;
@property (nonatomic, strong) NSString *manufacturerName; //matches api device_manufacturer

//Designated Initializer
- (id) initWithBrandName: (NSString *)name
          withBrandImage: (UIImage *)image
        withManufacturer: (NSString *)manufacturer;

- (id) init;


@end
