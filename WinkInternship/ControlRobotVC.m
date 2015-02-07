//
//  ControlRobotVC.m
//  WinkInternship
//
//  Created by Alex Ryan on 2/5/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import "ControlRobotVC.h"
#import "LightInWink.h"


static NSString * const BaseAPIString = @"https://winkapi.quirky.com/";
static NSString * const kAccessToken = @"access_token";
static NSString * const kRefreshToken = @"refresh_token";
static NSString * const kUsername = @"usernamekey";
static NSString * const kPassword = @"passwordkey";
static NSString * const kLoggedIn = @"loggedinalready";

@interface ControlRobotVC ()

@property (nonatomic, strong) NSMutableArray *activeLightsForTemperatureEffect;

@end

@implementation ControlRobotVC

@synthesize userLights, activeLightsForTemperatureEffect;


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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

    
    /*
    if (tappedImage.image == [UIImage imageNamed:@"BulbLit"]) {
        NSLog(@"Turn bulb off");
        tappedImage.image = [UIImage imageNamed:@"BulbOff"];
        [self.activeLightsForTemperatureEffect removeObject:[NSNumber numberWithInteger:lightID]];
    } else {
        NSLog(@"Turn bulb on");
        tappedImage.image = [UIImage imageNamed:@"BulbLit"];
        [self.activeLightsForTemperatureEffect addObject:[NSNumber numberWithInteger:lightID]];
    }
    
    NSLog(@"Current Active Lights = %@", self.activeLightsForTemperatureEffect);
    */
    
    
    /*
     //Remove old tap gesture recognizers
     for (UIGestureRecognizer *gr in tappedIconView.gestureRecognizers) {
     [tappedIconView removeGestureRecognizer:gr];
     }
     
     //Add back a gesture recognizer for unfollow user
     UITapGestureRecognizer *tapUnFollow = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(unFollowUser:)];
     [tappedIconView addGestureRecognizer:tapUnFollow];
     
     */
    
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






@end
