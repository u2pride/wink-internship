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
#import "ThermostatInWink.h"

static NSString * const BaseAPIString = @"https://winkapi.quirky.com/";
static NSString * const kAccessToken = @"access_token";
static NSString * const kRefreshToken = @"refresh_token";
static NSString * const kUsername = @"usernamekey";
static NSString * const kPassword = @"passwordkey";
static NSString * const kLoggedIn = @"loggedinalready";

@interface ControlRobotVC ()

@property (nonatomic, strong) NSNumber *numberOfWarmSliderValueUpdates;
@property (nonatomic, strong) NSNumber *numberOfCoolSliderValueUpdates;

@property (nonatomic, strong) NSTimer *timerToResetImages;

@property (nonatomic, strong) NSMutableArray *allLightImageViews;
@property (nonatomic, strong) NSMutableArray *activeLightsForTemperatureEffect;
@property (weak, nonatomic) IBOutlet UISlider *warmSlider;
@property (weak, nonatomic) IBOutlet UISlider *coolSlider;
@property (weak, nonatomic) IBOutlet UILabel *thermostatStatusLabel;
- (IBAction)warmSliderChangedValue:(id)sender;
- (IBAction)coolSliderChangedValue:(id)sender;

@end

@implementation ControlRobotVC

@synthesize userLights, activeLightsForTemperatureEffect, warmSlider, coolSlider, numberOfCoolSliderValueUpdates, numberOfWarmSliderValueUpdates, timerToResetImages, thermostatStatusLabel;


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //self.timerToResetImages = [[NSTimer alloc] init];
    
    //Setup Sliders
    self.coolSlider.minimumValue = 5500;
    self.coolSlider.maximumValue = 10000;

    self.warmSlider.minimumValue = 1000;
    self.warmSlider.maximumValue = 5500;
    
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
    

    [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(checkThermostatMode) userInfo:nil repeats:YES];
    
    
}


- (void)checkThermostatMode {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *accessToken = [userDefaults objectForKey:kAccessToken];
    
    NSString *valueForHTTPHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
    
    //Assuming one thermostat
    ThermostatInWink *thermostat = [self.userThermostats firstObject];
    
    NSString *urlString = [NSString stringWithFormat:@"https://winkapi.quirky.com/thermostats/%@", thermostat.thermostatID];
    
    //Call to the API using User Token to Find Light Resources
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
                                      }
                                      
                                      if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                          NSLog(@"Response HTTP Status code: %ld\n", (long)[(NSHTTPURLResponse *)response statusCode]);
                                          NSLog(@"Response HTTP Headers:\n%@\n", [(NSHTTPURLResponse *)response allHeaderFields]);
                                      }
                                      
                                      //TODO = push out to a separate function
                                      
                                      NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                      NSLog(@"Response Body:\n%@\n", body);
                                      
                                      
                                      NSError *errorJSON;
                                      NSMutableDictionary *thermostatMD = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&errorJSON];
                                      
                                      NSArray *thermostatData = [thermostatMD objectForKey:@"data"];
                                    
                                      
                                      
                                      NSDictionary *thermostatDictionary = [thermostatData firstObject];
                                      
                                      NSString *mode = thermostatDictionary[@"mode"];
                                      NSString *powereed = thermostatDictionary[@"powered"];
                                      
                                      if ([powereed isEqualToString:@"on"]) {
                                          
                                          if ([mode isEqualToString:@"heat"]) {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  [self updateTemperatureOfActiveLights:self.warmSlider.value];
                                              });
                                              self.thermostatStatusLabel.text = @"Thermostat Status: Heat";
                                              
                                          } else if ([mode isEqualToString:@"cool"]) {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  [self updateTemperatureOfActiveLights:self.coolSlider.value];
                                              });
                                              
                                              self.thermostatStatusLabel.text = @"Thermostat Status: Cool";
                                          }
                                          
                                      } else {

                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              [self updateTemperatureOfActiveLights:6500];
                                          });
                                          
                                          self.thermostatStatusLabel.text = @"Thermostat Status: Off";
                                      }
                                      
                                      

                                      
                                  }];
    [task resume];
    
    
}




- (void)updateTemperatureOfActiveLights:(float)temperature {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *accessToken = [userDefaults objectForKey:kAccessToken];
    
    NSString *valueForHTTPHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
    
    for (LightInWink *light in self.userLights) {
        
        NSString *stringForURL = [NSString stringWithFormat:@"https://winkapi.quirky.com/light_bulbs/%@", light.lightID];
        
        //Call to the API using User Token to Find Light Resources
        NSURL *url = [NSURL URLWithString:stringForURL];
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
        
        
    } else {
        NSLog(@"Turn bulb on");
        tappedImage.image = [UIImage imageNamed:@"BulbLit"];
        [self.activeLightsForTemperatureEffect addObject:[NSNumber numberWithFloat:lightID]];
        
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
            [temperatureAdjustment setValue:[CIVector vectorWithX:500 Y:0] forKey:@"inputNeutral"];
            [temperatureAdjustment setValue:[CIVector vectorWithX:slider.value Y:0] forKey:@"inputTargetNeutral"];
            
            //CIImage *outputImage = [temperatureAdjustment valueForKey:@"outputImage"];
            CIImage *outputImage = [temperatureAdjustment outputImage];
        
            CIContext *context = [CIContext contextWithOptions:nil];
            
            lightBulbImageView.image = [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:outputImage.extent]];;
 
            
        }
        
        NSLog(@"self.timerToResetImage : %@", self.timerToResetImages);
        if (self.timerToResetImages) {
            [self.timerToResetImages invalidate];
            self.timerToResetImages = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(resetImageViews) userInfo:nil repeats:NO];
            NSLog(@"reset old timer and start another");
        } else {
            self.timerToResetImages = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(resetImageViews) userInfo:nil repeats:NO];
            NSLog(@"Create a timer");
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
            [temperatureAdjustment setValue:[CIVector vectorWithX:300 Y:0] forKey:@"inputTargetNeutral"];
            
            //CIImage *outputImage = [temperatureAdjustment valueForKey:@"outputImage"];
            CIImage *outputImage = [temperatureAdjustment outputImage];
            
            CIContext *context = [CIContext contextWithOptions:nil];
            
            lightBulbImageView.image = [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:outputImage.extent]];;
            
            
        }
        
        
        NSLog(@"self.timerToResetImage : %@", self.timerToResetImages);
        if (self.timerToResetImages) {
            [self.timerToResetImages invalidate];
            self.timerToResetImages = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(resetImageViews) userInfo:nil repeats:NO];
            NSLog(@"reset old timer and start another");
        } else {
            self.timerToResetImages = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(resetImageViews) userInfo:nil repeats:NO];
            NSLog(@"Create a timer");
        }
        
        self.numberOfCoolSliderValueUpdates = 0;
    }
    
    NSNumber *incrementNumber = [NSNumber numberWithInt:[self.numberOfCoolSliderValueUpdates intValue] + 1];
    self.numberOfCoolSliderValueUpdates = incrementNumber;
    
    
}

- (void)resetImageViews {
    
    NSLog(@"RESET CALLED");
    
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

@end
