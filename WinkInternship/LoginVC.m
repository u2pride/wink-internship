//
//  ViewController.m
//  WinkInternship
//
//  Created by Alex Ryan on 2/4/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//


#import "LoginVC.h"
#import <CoreImage/CoreImage.h>

static NSString * const BaseAPIString = @"https://winkapi.quirky.com/";
static NSString * const kAccessToken = @"access_token";
static NSString * const kRefreshToken = @"refresh_token";
static NSString * const kUsername = @"usernamekey";
static NSString * const kPassword = @"passwordkey";

static NSString * const kClientID = @"2ec4f93efd4390a33f6b8dcb12875377";
static NSString * const kClientSecret = @"d7d606469be78ac2a3fce4e5419ab4f1";

@interface LoginVC ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *winkImageView;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;

- (IBAction)login:(id)sender;

@end



@implementation LoginVC

@synthesize usernameTextField, passwordTextField, winkImageView, loginButton, activitySpinner;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Setup View
    self.view.backgroundColor = [UIColor colorWithRed:0 green:0.722 blue:0.945 alpha:1];
    self.winkImageView.image = [UIImage imageNamed:@"WinkLogo"];
    self.passwordTextField.delegate = self;
    self.usernameTextField.delegate = self;
    self.loginButton.layer.cornerRadius = 15;
    
    self.activitySpinner.hidesWhenStopped = YES;

}


// Method Fired When Login Button is Pressed
- (IBAction)login:(id)sender {
    
    [self.activitySpinner startAnimating];
    
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    
    //Save Username and Password to Defaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:username forKey:kUsername];
    [userDefaults setObject:password forKey:kPassword];
    
    [userDefaults synchronize];
    
    
    //Create Strings for API Request
    NSString *httpBodyString = [NSString stringWithFormat:@"{\n    \"client_id\": \"%@\",\n    \"client_secret\": \"%@\",\n    \"username\": \"%@\",\n    \"password\": \"%@\",\n    \"grant_type\": \"password\"\n}", kClientID, kClientSecret, username, password];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/oauth2/token", BaseAPIString];
    
    //Creating and Starting Request
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[httpBodyString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      
                                      if (error) {
                                          
                                          UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Username or Password Not Found" delegate:self cancelButtonTitle:@"done" otherButtonTitles: nil];
                    
                                          [errorAlert show];
                                          
                                          return;
                                          
                                      } else {
                                          
                                          NSError *errorJSON;
                                          NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&errorJSON];
                                          
                                          //Extract Tokens from Response
                                          NSString *accessToken = [json objectForKey:@"access_token"];
                                          NSString *refreshToken = [json objectForKey:@"refresh_token"];
                                          
                                          //Store Tokens to User Preferences - Could be Used to Determine if the User is Already Logged In and Setup
                                          NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                                          
                                          [userDefaults setObject:accessToken forKey:kAccessToken];
                                          [userDefaults setObject:refreshToken forKey:kRefreshToken];
                                          
                                          [userDefaults synchronize];
                                          
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              [self.activitySpinner stopAnimating];
                                              [self performSegueWithIdentifier:@"loginToSetup" sender:self];
                                          });

                                          
                                      }
                                      
                                      
                                  }];
    [task resume];




}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}



@end
