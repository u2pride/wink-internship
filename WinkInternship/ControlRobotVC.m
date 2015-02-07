//
//  ControlRobotVC.m
//  WinkInternship
//
//  Created by Alex Ryan on 2/5/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import "ControlRobotVC.h"
#import "LightInWink.h"
#import <CoreImage/CoreImage.h>

static NSString * const BaseAPIString = @"https://winkapi.quirky.com/";
static NSString * const kAccessToken = @"access_token";
static NSString * const kRefreshToken = @"refresh_token";
static NSString * const kUsername = @"usernamekey";
static NSString * const kPassword = @"passwordkey";
static NSString * const kLoggedIn = @"loggedinalready";

@interface ControlRobotVC ()

@property (nonatomic, strong) NSNumber *numberOfWarmSliderValueUpdates;
@property (nonatomic, strong) NSNumber *numberOfCoolSliderValueUpdates;


@property (nonatomic, strong) NSMutableArray *allLightImageViews;
@property (nonatomic, strong) NSMutableArray *activeLightsForTemperatureEffect;
@property (weak, nonatomic) IBOutlet UISlider *warmSlider;
@property (weak, nonatomic) IBOutlet UISlider *coolSlider;
- (IBAction)warmSliderChangedValue:(id)sender;
- (IBAction)coolSliderChangedValue:(id)sender;

@end

@implementation ControlRobotVC

@synthesize userLights, activeLightsForTemperatureEffect, warmSlider, coolSlider, numberOfCoolSliderValueUpdates, numberOfWarmSliderValueUpdates;


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //Setup Sliders
    self.coolSlider.minimumValue = 0;
    self.coolSlider.maximumValue = 10000;

    self.warmSlider.minimumValue = 0;
    self.warmSlider.maximumValue = 10000;
    
    self.numberOfWarmSliderValueUpdates = 0;
    self.numberOfCoolSliderValueUpdates = 0;

    self.allLightImageViews = [[NSMutableArray alloc] init];
    self.activeLightsForTemperatureEffect = [[NSMutableArray alloc] init];
    
    NSArray *allLights = self.userLights;
    
    NSLog(@"WHERE WE AT: %@", self.userLights);
    for (LightInWink *light in allLights) {
        NSLog(@"%@", light.lightName);
        NSLog(@"%@", light.lightID);
        NSLog(@"%@", light.lightManufacturer);

    }
    
    //Set Navigation Bar
    [self.navigationItem setTitle:@"Control"];
    self.navigationItem.leftBarButtonItem.title = @"";

    
    //Each Light Found in the Previous Step is Represented with an Light Bulb Image
    
    CGRect initialFrame = CGRectMake(20, self.view.frame.size.height - 120, 100, 100);
    
    for (LightInWink *light in self.userLights) {
        UIImageView *lightImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BulbOff"]];
        lightImageView.frame = initialFrame;
        //used to identify the lightImageView
        lightImageView.tag = [light.lightID intValue];
        //update the frame
        initialFrame.origin.x +=100;
        //add a tap gesture Recognizer
        lightImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapLight = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enableDisableLight:)];
        [lightImageView addGestureRecognizer:tapLight];
        //add to view
        [self.view addSubview:lightImageView];
        
        [self.allLightImageViews addObject:lightImageView];
    }
    

    
}


- (void)enableDisableLight:(UITapGestureRecognizer *)tapgr {
    UIImageView *tappedImage = (UIImageView *)tapgr.view;

    long lightID = (long)tappedImage.tag;
    NSLog(@"LightID: %ld", (long)tappedImage.tag);
    
    BOOL foundLightID = false;
    
    for (int i = 0; i < self.activeLightsForTemperatureEffect.count; i++) {
        
        long lightIDOfActiveLights = [self.activeLightsForTemperatureEffect[i] floatValue];
        if (lightIDOfActiveLights == lightID) {
            foundLightID = true;
        }
        
    }
    
    
    if (foundLightID) {
        NSLog(@"Turn bulb off");
        tappedImage.image = [UIImage imageNamed:@"BulbOff"];
        [self.activeLightsForTemperatureEffect removeObject:[NSNumber numberWithFloat:lightID]];
        
        
        /*
        CIImage *inputImage = [[CIImage alloc] initWithImage:[UIImage imageNamed:@"BulbOff"]];
        CIFilter *temperatureAdjustment = [CIFilter filterWithName:@"CITemperatureAndTint"];
        
        [temperatureAdjustment setDefaults];
        [temperatureAdjustment setValue:inputImage forKey:@"inputImage"];
        [temperatureAdjustment setValue:[CIVector vectorWithX:10000 Y:0] forKey:@"inputNeutral"];
        [temperatureAdjustment setValue:[CIVector vectorWithX:10000 Y:0] forKey:@"inputTargetNeutral"];
        
        CIImage *outputImage = [temperatureAdjustment valueForKey:@"outputImage"];
        
        CIContext *context = [CIContext contextWithOptions:nil];
        tappedImage.image = [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:outputImage.extent]];
        */
        
        
        
        
        
    } else {
        NSLog(@"Turn bulb on");
        tappedImage.image = [UIImage imageNamed:@"BulbLit"];
        [self.activeLightsForTemperatureEffect addObject:[NSNumber numberWithFloat:lightID]];
        
        
        /*
        CIImage *inputImage = [[CIImage alloc] initWithImage:[UIImage imageNamed:@"BulbLit"]];
        CIFilter *temperatureAdjustment = [CIFilter filterWithName:@"CITemperatureAndTint"];
        
        [temperatureAdjustment setDefaults];
        [temperatureAdjustment setValue:inputImage forKey:@"inputImage"];
        [temperatureAdjustment setValue:[CIVector vectorWithX:100 Y:0] forKey:@"inputNeutral"];
        [temperatureAdjustment setValue:[CIVector vectorWithX:10000 Y:0] forKey:@"inputTargetNeutral"];
        
        CIImage *outputImage = [temperatureAdjustment valueForKey:@"outputImage"];
        
        CIContext *context = [CIContext contextWithOptions:nil];
        tappedImage.image = [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:outputImage.extent]];
         
        */
        
    }
    
    NSLog(@"Current Active Lights = %@", self.activeLightsForTemperatureEffect);

    
}

- (IBAction)startLightCorrection:(id)sender {
    
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *accessToken = [userDefaults objectForKey:kAccessToken];
    
    NSString *valueForHTTPHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
    
    LightInWink *exampleLight = [self.userLights objectAtIndex:1];
    
    NSString *stringForURL = [NSString stringWithFormat:@"https://winkapi.quirky.com/light_bulbs/%@", exampleLight.lightID];
    
    //Call to the API using User Token to Find Light Resources
    NSURL *url = [NSURL URLWithString:stringForURL];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setHTTPMethod:@"PUT"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:valueForHTTPHeader forHTTPHeaderField:@"Authorization"];
    

    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithBool:true],
                          @"powered",
                          [NSNumber numberWithFloat:1.0],
                          @"brightness",
                          nil];
    
    NSDictionary* info2 = [NSDictionary dictionaryWithObjectsAndKeys:
                           info,
                           @"desired_state",
                           nil];
    
    NSError *errorJSON;
    //convert object to data
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:info2 options:NSJSONWritingPrettyPrinted error:&errorJSON];
    
    NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    
    
    //[urlRequest setHTTPBody:jsonData];

    
    
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      
                                      if (error) {
                                          
                                          UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error in Request" delegate:self cancelButtonTitle:@"done" otherButtonTitles: nil];
                                          
                                          [errorAlert show];
                                          
                                          return;
                                      }
                                      
                                      if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                          NSLog(@"Response HTTP Status code: %ld\n", (long)[(NSHTTPURLResponse *)response statusCode]);
                                          NSLog(@"Response HTTP Headers:\n%@\n", [(NSHTTPURLResponse *)response allHeaderFields]);
                                      }
                                      
                                      NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                      NSLog(@"Response Body:\n%@\n", body);
                                      
                                                                            
                                      
                                  }];
    [task resume];
    
}






- (IBAction)warmSliderChangedValue:(id)sender {
    
    NSLog(@"Number Of Updates: %@", self.numberOfWarmSliderValueUpdates);
    
    if (self.numberOfWarmSliderValueUpdates.integerValue > 10) {
        
        for (UIImageView *lightBulbImageView in self.allLightImageViews) {
        
            //UIImageView *lightBulbImageView = [self.allLightImageViews firstObject];
        
            NSLog(@"%@", lightBulbImageView);
            UISlider *slider = (UISlider *)sender;
            NSLog(@"slidervalue: %f", slider.value);
            
            CIImage *inputImage = [[CIImage alloc] initWithImage:lightBulbImageView.image];
            CIFilter *temperatureAdjustment = [CIFilter filterWithName:@"CITemperatureAndTint"];
            
            [temperatureAdjustment setDefaults];
            [temperatureAdjustment setValue:inputImage forKey:@"inputImage"];
            [temperatureAdjustment setValue:[CIVector vectorWithX:6500 Y:0] forKey:@"inputNeutral"];
            [temperatureAdjustment setValue:[CIVector vectorWithX:slider.value Y:0] forKey:@"inputTargetNeutral"];
            
            //CIImage *outputImage = [temperatureAdjustment valueForKey:@"outputImage"];
            CIImage *outputImage = [temperatureAdjustment outputImage];
        
            CIContext *context = [CIContext contextWithOptions:nil];
            
            lightBulbImageView.image = [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:outputImage.extent]];;
 
            
        }

        self.numberOfWarmSliderValueUpdates = 0;
    }
    
    NSNumber *incrementNumber = [NSNumber numberWithInt:[self.numberOfWarmSliderValueUpdates intValue] + 1];
    self.numberOfWarmSliderValueUpdates = incrementNumber;
    
}



- (IBAction)coolSliderChangedValue:(id)sender {
    
    NSLog(@"Number Of Updates: %@", self.numberOfCoolSliderValueUpdates);
    
    if (self.numberOfCoolSliderValueUpdates.integerValue > 10) {
        
        for (UIImageView *lightBulbImageView in self.allLightImageViews) {
            
            //UIImageView *lightBulbImageView = [self.allLightImageViews firstObject];
            
            NSLog(@"%@", lightBulbImageView);
            UISlider *slider = (UISlider *)sender;
            NSLog(@"slidervalue: %f", slider.value);
            
            CIImage *inputImage = [[CIImage alloc] initWithImage:lightBulbImageView.image];
            CIFilter *temperatureAdjustment = [CIFilter filterWithName:@"CITemperatureAndTint"];
            
            [temperatureAdjustment setDefaults];
            [temperatureAdjustment setValue:inputImage forKey:@"inputImage"];
            [temperatureAdjustment setValue:[CIVector vectorWithX:slider.value Y:0] forKey:@"inputNeutral"];
            [temperatureAdjustment setValue:[CIVector vectorWithX:6500 Y:0] forKey:@"inputTargetNeutral"];
            
            //CIImage *outputImage = [temperatureAdjustment valueForKey:@"outputImage"];
            CIImage *outputImage = [temperatureAdjustment outputImage];
            
            CIContext *context = [CIContext contextWithOptions:nil];
            
            lightBulbImageView.image = [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:outputImage.extent]];;
            
            
        }
        
        self.numberOfCoolSliderValueUpdates = 0;
    }
    
    NSNumber *incrementNumber = [NSNumber numberWithInt:[self.numberOfCoolSliderValueUpdates intValue] + 1];
    self.numberOfCoolSliderValueUpdates = incrementNumber;
    
    
}


@end
