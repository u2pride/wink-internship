//
//  ViewController.m
//  WinkInternship
//
//  Created by Alex Ryan on 2/4/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//


#import "ViewController.h"
#import <CoreImage/CoreImage.h>

static NSString * const BaseAPIString = @"https://winkapi.quirky.com/";
static NSString * const kAccessToken = @"access_token";
static NSString * const kRefreshToken = @"refresh_token";
static NSString * const kUsername = @"usernamekey";
static NSString * const kPassword = @"passwordkey";
static NSString * const kLoggedIn = @"loggedinalready";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *winkImageView;


- (IBAction)login:(id)sender;


@end

@implementation ViewController

@synthesize usernameTextField, passwordTextField, winkImageView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *loggedIn = [userDefaults objectForKey:kLoggedIn];
    if ([loggedIn isEqualToString:@"yes"]) {
        //[self performSegueWithIdentifier:@"loginToControl" sender:self];
        NSLog(@"Logged In");
    }
    
    //Setup View
    self.view.backgroundColor = [UIColor colorWithRed:0 green:0.722 blue:0.945 alpha:1];

    self.winkImageView.image = [UIImage imageNamed:@"WinkLogo"];
    
    self.passwordTextField.delegate = self;
    self.usernameTextField.delegate = self;
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    /*

    NSString *clientID = nil; //add to here instead of directly in string - same with client secret
    
    
    NSURL *URL = [NSURL URLWithString:@"https://winkapi.quirky.com/users/me/wink_devices"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:@"GET"];
    
    [request setValue:@"Bearer 4430835b6071aa0aa16f489f177d809f" forHTTPHeaderField:@"Authorization"];
    
    //[request setHTTPBody:[@"{\n    \"client_id\": \"2ec4f93efd4390a33f6b8dcb12875377\",\n    \"client_secret\": \"d7d606469be78ac2a3fce4e5419ab4f1\",\n    \"username\": \"thomas.alexander.ryan@gmail.com\",\n    \"password\": \"1Wink2\",\n    \"grant_type\": \"password\"\n}" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      
                                      if (error) {
                                          NSLog(@"Error: %@", error);
                                          
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
    
    NSArray *availableEffects = [CIFilter filterNamesInCategory:kCICategoryColorEffect];
    
    NSLog(@"%@", availableEffects);
    
    CIFilter *exampleFilter = [CIFilter filterWithName:@"CISephiaTone"];
    
    UIImage *filteredImage = [exampleFilter appl]
    
    */
    
    
    
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    

    /*
    
    self.thisIsImage.image = currentBrandImage;
    
    // 2
    CIImage *beginImage = currentBrandImage.CIImage;
    // 3
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone" keysAndValues: kCIInputImageKey, beginImage, @"inputIntensity", @0.1, nil];
    CIImage *outputImage = [filter outputImage];
    
    // 4
    UIImage *newImage = [UIImage imageWithCIImage:outputImage];
    self.thisIsImage.image = newImage;
    */
}

- (IBAction)login:(id)sender {
    
    
    
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    
    //Save Username and Password to Defaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:username forKey:kUsername];
    [userDefaults setObject:password forKey:kPassword];
    
    [userDefaults synchronize];
    
    
    
    NSURL *URL = [NSURL URLWithString:@"https://winkapi.quirky.com/oauth2/token"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setHTTPBody:[@"{\n    \"client_id\": \"2ec4f93efd4390a33f6b8dcb12875377\",\n    \"client_secret\": \"d7d606469be78ac2a3fce4e5419ab4f1\",\n    \"username\": \"thomas.alexander.ryan@gmail.com\",\n    \"password\": \"1Wink2\",\n    \"grant_type\": \"password\"\n}" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      
                                      if (error) {
                                          // Handle error...
                                          return;
                                      }
                                      
                                      if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                          NSLog(@"Response HTTP Status code: %ld\n", (long)[(NSHTTPURLResponse *)response statusCode]);
                                          NSLog(@"Response HTTP Headers:\n%@\n", [(NSHTTPURLResponse *)response allHeaderFields]);
                                      }
                                      
                                      NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                      NSLog(@"Response Body:\n%@\n", body);
                                      
                                      NSError *error2;
                                      NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error2];
                                      
                                      NSString *accessToken = [json objectForKey:@"access_token"];
                                      NSLog(@"Access Token: %@", accessToken);
                                      
                                      NSString *refreshToken = [json objectForKey:@"refresh_token"];
                                      NSLog(@"Refresh Token: %@", refreshToken);
                                      
                                      //Store Tokens to User Preferences
                                      NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                                      
                                      [userDefaults setObject:accessToken forKey:kAccessToken];
                                      [userDefaults setObject:refreshToken forKey:kRefreshToken];
                                      [userDefaults setObject:@"yes" forKey:kLoggedIn];
                                      
                                      [userDefaults synchronize];
                                      
                                      [self performSegueWithIdentifier:@"loginToSetup" sender:self];
                                      
                                  }];
    [task resume];




}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}


@end
