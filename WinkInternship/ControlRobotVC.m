//
//  ControlRobotVC.m
//  WinkInternship
//
//  Created by Alex Ryan on 2/5/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import "ControlRobotVC.h"
#import "LightInWink.h"
#import "ThermostatInWink.h"
#import <CoreImage/CoreImage.h>

static NSString * const BaseAPIString = @"https://winkapi.quirky.com/";
static NSString * const kAccessToken = @"access_token";
static NSString * const kRefreshToken = @"refresh_token";

@interface ControlRobotVC ()

@property (nonatomic, strong) NSMutableArray *allLightImageViews;
@property (nonatomic, strong) NSMutableArray *activeLightsForTemperatureEffect;

@property (weak, nonatomic) IBOutlet UILabel *headingText;
@property (weak, nonatomic) IBOutlet UISlider *warmSlider;
@property (weak, nonatomic) IBOutlet UISlider *coolSlider;
@property (weak, nonatomic) IBOutlet UILabel *thermostatStatusLabel;

//Properties to Control Warm/Cool Previews
@property (nonatomic, strong) NSNumber *numberOfWarmSliderValueUpdates;
@property (nonatomic, strong) NSNumber *numberOfCoolSliderValueUpdates;
@property (nonatomic, strong) NSTimer *timerToResetImages;

- (IBAction)warmSliderChangedValue:(id)sender;
- (IBAction)coolSliderChangedValue:(id)sender;

@end

@implementation ControlRobotVC

@synthesize userLights, userThermostats;

@synthesize allLightImageViews, activeLightsForTemperatureEffect, warmSlider, coolSlider, thermostatStatusLabel, numberOfCoolSliderValueUpdates, numberOfWarmSliderValueUpdates, timerToResetImages, headingText;


- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.headingText.text = @"Use this page to change the amount of temperature difference that appears in your lights when your thermostat is heating or cooling your house.";
    
    //Setup Sliders For Min and Max Temperature Values
    self.coolSlider.minimumValue = 5500;
    self.coolSlider.maximumValue = 10000;

    self.warmSlider.minimumValue = 1000;
    self.warmSlider.maximumValue = 5500;
    
    self.coolSlider.minimumValueImage = [UIImage imageNamed:@"CoolMin"];
    self.coolSlider.maximumValueImage = [UIImage imageNamed:@"CoolMax"];
    
    self.warmSlider.minimumValueImage = [UIImage imageNamed:@"WarmMin"];
    self.warmSlider.maximumValueImage = [UIImage imageNamed:@"WarmMax"];
    
    //Used to limit slider value updates
    self.numberOfWarmSliderValueUpdates = 0;
    self.numberOfCoolSliderValueUpdates = 0;

    //initialize arrays
    self.allLightImageViews = [[NSMutableArray alloc] init];
    self.activeLightsForTemperatureEffect = [[NSMutableArray alloc] init];
    
    
    //Adjustment to the Navigation Bar Title
    [self.navigationItem setTitle:@"Control"];
    
    //Each Light Found in the Previous Step is Represented with an Light Bulb Image
    CGRect initialFrame = CGRectMake(20, self.view.frame.size.height - 120, 80, 80);
    
    for (LightInWink *light in self.userLights) {
        UIImageView *lightImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BulbOff"]];
        lightImageView.frame = initialFrame;
        //used to identify the lightImageView
        lightImageView.tag = [light.lightID intValue];
        //update the frame
        initialFrame.origin.x += 80;
        //add a tap gesture Recognizer
        lightImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapLight = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enableDisableLight:)];
        [lightImageView addGestureRecognizer:tapLight];
        //add to view
        [self.view addSubview:lightImageView];
        
        [self.allLightImageViews addObject:lightImageView];
    }
    

    //Every minute, check the thermostat status
    //If heating, then adjust the temperature of the connected lights by the value of the warm slider.
    //If cooling, then adjust the temperature of the connected lights by the value of the cool slider.
    [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(checkThermostatMode) userInfo:nil repeats:YES];
    
    
}


//Check the thermostat power and mode
- (void)checkThermostatMode {
    
    //Assuming one thermostat
    ThermostatInWink *thermostat = [self.userThermostats firstObject];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *accessToken = [userDefaults objectForKey:kAccessToken];
    
    NSString *valueForHTTPHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
    NSString *urlString = [NSString stringWithFormat:@"%@/thermostats/%@", BaseAPIString, thermostat.thermostatID];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:valueForHTTPHeader forHTTPHeaderField:@"Authorization"];
    
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      
                                      if (error) {
                                          
                                          UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error in Request" delegate:self cancelButtonTitle:@"done" otherButtonTitles: nil];
                                          
                                          [errorAlert show];
                                          
                                          return;
                                      } else {
                                          
                                          NSError *errorJSON;
                                          NSMutableDictionary *thermostatMD = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&errorJSON];
                                          
                                          NSArray *thermostatData = [thermostatMD objectForKey:@"data"];
                                          NSDictionary *thermostatDictionary = [thermostatData firstObject];
                                          
                                          //Grab the thermostat mode and powered status
                                          NSString *mode = thermostatDictionary[@"mode"];
                                          NSString *powered = thermostatDictionary[@"powered"];
                                          
                                          if ([powered isEqualToString:@"on"]) {
                                              
                                              if ([mode isEqualToString:@"heat"]) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self updateTemperatureOfActiveLights:self.warmSlider.value];
                                                  });
                                                  
                                                  self.thermostatStatusLabel.text = @"HEAT";
                                                  
                                              } else if ([mode isEqualToString:@"cool"]) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self updateTemperatureOfActiveLights:self.coolSlider.value];
                                                  });
                                                  
                                                  self.thermostatStatusLabel.text = @"COOL";
                                              }
                                              
                                          } else {
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  [self updateTemperatureOfActiveLights:6500];
                                              });
                                              
                                              self.thermostatStatusLabel.text = @"OFF";
                                          }
                                          
                                      }
                                      
                                      
                                  }];
    [task resume];
    
    
}



//PUT Temperature Updates to the Lights Currently Selected by the User
//Note: Temperature Property does not currently exist in API for lights.
- (void)updateTemperatureOfActiveLights:(float)temperature {
        
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *accessToken = [userDefaults objectForKey:kAccessToken];
    
    NSString *valueForHTTPHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
    
    //Grab each light and Update the Temperature Based on Thermostat Status
    for (NSNumber *lightID in self.activeLightsForTemperatureEffect) {
        
        NSString *urlString = [NSString stringWithFormat:@"%@/light_bulbs/%@", BaseAPIString, lightID];
        NSLog(@"urlSTring : %@", urlString);
        
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        
        [urlRequest setHTTPMethod:@"PUT"];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [urlRequest setValue:valueForHTTPHeader forHTTPHeaderField:@"Authorization"];
        
        
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat:temperature],
                              @"temperature",
                              nil];
        
        NSDictionary* info2 = [NSDictionary dictionaryWithObjectsAndKeys:
                               info,
                               @"desired_state",
                               nil];
        
        NSError *errorJSON;
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:info2 options:NSJSONWritingPrettyPrinted error:&errorJSON];
        
        [urlRequest setHTTPBody:jsonData];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest
                                                completionHandler:
                                      ^(NSData *data, NSURLResponse *response, NSError *error) {
                                          
                                          if (error) {
                                              
                                              UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error Updating Lights" delegate:self cancelButtonTitle:@"done" otherButtonTitles: nil];
                                              
                                              [errorAlert show];
                                              
                                              return;
                                          } else {
                                              
                                              NSLog(@"Light Temperature Updated");
                                              
                                          }
                                        
                                      }];
        [task resume];
        
    }
}




// Method called when a light is tapped to update light image and active lights collection
- (void)enableDisableLight:(UITapGestureRecognizer *)tapgr {
    
    UIImageView *tappedImage = (UIImageView *)tapgr.view;

    long lightID = (long)tappedImage.tag;
    BOOL foundLightID = false;
    
    for (int i = 0; i < self.activeLightsForTemperatureEffect.count; i++) {
        
        long lightIDOfActiveLights = [self.activeLightsForTemperatureEffect[i] floatValue];
        if (lightIDOfActiveLights == lightID) {
            foundLightID = true;
        }
        
    }
    
    if (foundLightID) {
        tappedImage.image = [UIImage imageNamed:@"BulbOff"];
        [self.activeLightsForTemperatureEffect removeObject:[NSNumber numberWithFloat:lightID]];
        
    } else {
        tappedImage.image = [UIImage imageNamed:@"BulbLit"];
        [self.activeLightsForTemperatureEffect addObject:[NSNumber numberWithFloat:lightID]];
        
    }
    

}





//Preview Warmth Adjustment on Light Bulb Images
//Note - I didn't figure out exactly how the CITemperatureAndTint filter works.
- (IBAction)warmSliderChangedValue:(id)sender {
    
    if (self.numberOfWarmSliderValueUpdates.integerValue > 10) {
        
        for (UIImageView *lightBulbImageView in self.allLightImageViews) {
            
            UISlider *slider = (UISlider *)sender;
            
            CIImage *inputImage = [[CIImage alloc] initWithImage:lightBulbImageView.image];
            CIFilter *temperatureAdjustment = [CIFilter filterWithName:@"CITemperatureAndTint"];
            
            [temperatureAdjustment setDefaults];
            [temperatureAdjustment setValue:inputImage forKey:@"inputImage"];
            [temperatureAdjustment setValue:[CIVector vectorWithX:500 Y:0] forKey:@"inputNeutral"];
            [temperatureAdjustment setValue:[CIVector vectorWithX:slider.value Y:0] forKey:@"inputTargetNeutral"];
            
            CIImage *outputImage = [temperatureAdjustment outputImage];
        
            CIContext *context = [CIContext contextWithOptions:nil];
            
            lightBulbImageView.image = [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:outputImage.extent]];;
            
        }
        
        //Preview Runs for 5 Seconds - If a Timer is Already Started, then stop it and start another.
        if (self.timerToResetImages) {
            [self.timerToResetImages invalidate];
            self.timerToResetImages = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(resetImageViews) userInfo:nil repeats:NO];
        } else {
            self.timerToResetImages = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(resetImageViews) userInfo:nil repeats:NO];
        }
        
        self.numberOfWarmSliderValueUpdates = 0;
    }
    
    NSNumber *incrementNumber = [NSNumber numberWithInt:[self.numberOfWarmSliderValueUpdates intValue] + 1];
    self.numberOfWarmSliderValueUpdates = incrementNumber;
    
}



//Preview Cool Adjustment on Light Bulb Images
//Note - I didn't figure out exactly how the CITemperatureAndTint filter works.
- (IBAction)coolSliderChangedValue:(id)sender {
    
    if (self.numberOfCoolSliderValueUpdates.integerValue > 10) {
        
        for (UIImageView *lightBulbImageView in self.allLightImageViews) {
            
            UISlider *slider = (UISlider *)sender;
            
            CIImage *inputImage = [[CIImage alloc] initWithImage:lightBulbImageView.image];
            CIFilter *temperatureAdjustment = [CIFilter filterWithName:@"CITemperatureAndTint"];
            
            [temperatureAdjustment setDefaults];
            [temperatureAdjustment setValue:inputImage forKey:@"inputImage"];
            [temperatureAdjustment setValue:[CIVector vectorWithX:slider.value Y:0] forKey:@"inputNeutral"];
            [temperatureAdjustment setValue:[CIVector vectorWithX:300 Y:0] forKey:@"inputTargetNeutral"];
            
            CIImage *outputImage = [temperatureAdjustment outputImage];
            
            CIContext *context = [CIContext contextWithOptions:nil];
            
            lightBulbImageView.image = [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:outputImage.extent]];;

        }
        
        //Preview Runs for 5 Seconds - If a Timer is Already Started, then stop it and start another.
        if (self.timerToResetImages) {
            [self.timerToResetImages invalidate];
            self.timerToResetImages = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(resetImageViews) userInfo:nil repeats:NO];
        } else {
            self.timerToResetImages = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(resetImageViews) userInfo:nil repeats:NO];
        }
        
        self.numberOfCoolSliderValueUpdates = 0;
    }
    
    NSNumber *incrementNumber = [NSNumber numberWithInt:[self.numberOfCoolSliderValueUpdates intValue] + 1];
    self.numberOfCoolSliderValueUpdates = incrementNumber;
    
}


//Reset the Image Views to their Original State after the 5 Second Preview
- (void)resetImageViews {
    
    for (UIImageView *lightBulbImageView in self.allLightImageViews) {
        
        BOOL lightOn = false;
        
        for (int i = 0; i < self.activeLightsForTemperatureEffect.count; i++) {
            
            long lightIDOfActiveLights = [self.activeLightsForTemperatureEffect[i] floatValue];
            if (lightIDOfActiveLights == lightBulbImageView.tag) {
                lightOn = true;
            }
        }
        
        if (lightOn) {
            lightBulbImageView.image = [UIImage imageNamed:@"BulbLit"];
            
        } else {
            lightBulbImageView.image = [UIImage imageNamed:@"BulbOff"];

        }
        
    }

}



@end
