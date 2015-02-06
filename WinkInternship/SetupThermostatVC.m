//
//  SetupThermostatVC.m
//  WinkInternship
//
//  Created by Alex Ryan on 2/5/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import "BrandOfWink.h"
#import "BrandTableCell.h"
#import "SetupThermostatVC.h"
#import "ThermostatInWink.h"
#import <CoreImage/CoreImage.h>
#import "SetupLightsVC.h"

static NSString * const BaseAPIString = @"https://winkapi.quirky.com/";
static NSString * const kAccessToken = @"access_token";
static NSString * const kRefreshToken = @"refresh_token";
static NSString * const kUsername = @"usernamekey";
static NSString * const kPassword = @"passwordkey";
static NSString * const kLoggedIn = @"loggedinalready";

@interface SetupThermostatVC ()

@property (weak, nonatomic) IBOutlet UITableView *thermostatTable;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UILabel *resultTextLabel;

@property (nonatomic, strong) NSMutableArray *thermostatBrands;

@property (nonatomic, strong) NSMutableArray *allThermostats;
@property (nonatomic, strong) NSMutableArray *selectedThermostats;



@end

@implementation SetupThermostatVC

@synthesize thermostatTable, nextButton, resultTextLabel;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    //initialize arrays
    self.allThermostats = [[NSMutableArray alloc] init];
    self.selectedThermostats = [[NSMutableArray alloc] init];
    
    //Results Text label
    self.resultTextLabel.text = @"Select a Brand";
    
    //Create Brand Objects
    self.thermostatBrands = [[NSMutableArray alloc] init];
    
    BrandOfWink *nest = [[BrandOfWink alloc] initWithBrandName:@"Nest" withBrandImage:[UIImage imageNamed:@"Nest"] withManufacturer:@"nest"];
    BrandOfWink *quirky = [[BrandOfWink alloc] initWithBrandName:@"Quirky" withBrandImage:[UIImage imageNamed:@"Quirky"] withManufacturer:@"quirky"];
    BrandOfWink *honeywell = [[BrandOfWink alloc] initWithBrandName:@"Honeywell" withBrandImage:[UIImage imageNamed:@"Honeywell"] withManufacturer:@"honeywell"];
    
    [self.thermostatBrands addObject:nest];
    [self.thermostatBrands addObject:quirky];
    [self.thermostatBrands addObject:honeywell];
    
    
    //Adjustments to Navigation Bar
    [self.navigationItem setTitle:@"Setup Thermostat"];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0 green:0.722 blue:0.945 alpha:1]; /*#00b8f1*/
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.translucent = NO;

    
    //Adjustments to Table View, View,s and Button
    self.view.backgroundColor = [UIColor colorWithRed:0.965 green:0.965 blue:0.965 alpha:1.0];
    self.thermostatTable.layer.cornerRadius = 20;
    self.nextButton.layer.cornerRadius = 15;
    self.nextButton.titleLabel.text = @"Next";
    self.nextButton.backgroundColor = [UIColor colorWithRed:0 green:0.722 blue:0.945 alpha:1];
}



#pragma mark - UITableView Delegate/DataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *stringIdentifier = @"BrandCell";
    
    BrandTableCell *brandCell = [tableView dequeueReusableCellWithIdentifier:stringIdentifier forIndexPath:indexPath];
    
    BrandOfWink *currentBrand = [self.thermostatBrands objectAtIndex:indexPath.row];
    
    if (brandCell) {
        brandCell.brandImageView.image = currentBrand.brandImage;
    }
    
    return brandCell;
}

- (NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.thermostatBrands count];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BrandTableCell *currentCell = (BrandTableCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    BrandOfWink *selectedBrand = [self.thermostatBrands objectAtIndex:indexPath.row];
    NSString *manufacturer = selectedBrand.manufacturerName;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *accessToken = [userDefaults objectForKey:kAccessToken];
    
    NSString *valueForHTTPHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
    
    
    //Call to the API using User Token to Find Light Resources
    NSURL *url = [NSURL URLWithString:@"https://winkapi.quirky.com/users/me/thermostats"];
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
                                      NSMutableDictionary *allThermostats = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&errorJSON];
                                      
                                      NSArray *thermostats = [allThermostats objectForKey:@"data"];
                                      
                                      for (NSDictionary *thermostat in thermostats) {
                                          
                                          ThermostatInWink *newThermostat = [[ThermostatInWink alloc] initWithThermostatID:thermostat[@"thermostat_id"] withName:thermostat[@"name"] withManufacturer:thermostat[@"device_manufacturer"]];
                                          
                                          
                                          [self.allThermostats addObject:newThermostat];
                                          
                                          
                                          if ([newThermostat.thermostatManufacturer isEqualToString:manufacturer]) {
                                              
                                              [self.selectedThermostats addObject:newThermostat];
                                          }

                                      }
                                      
                                      self.resultTextLabel.text = [NSString stringWithFormat:@"Found %lu Thermostats", (unsigned long)self.selectedThermostats.count];
                                      
                                      
                                  }];
    [task resume];

    


    /*
    BrandTableCell *currentCell = (BrandTableCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    UIImage *currentBrandImage = currentCell.brandImageView.image;


    
    
    
    //Change what a Cell Looks like on Selection
    CIContext * context = [CIContext contextWithOptions:nil];
    CIImage * ciImage = [[CIImage alloc] initWithImage:currentBrandImage];
    
    CIFilter * blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:ciImage forKey:kCIInputImageKey];
    
    CGImageRef ref = [context createCGImage:blurFilter.outputImage fromRect:[blurFilter outputImage].extent];
    
    currentCell.brandImageView.image = [UIImage imageWithCGImage:ref];
    
    
    //Call to the API to find the Resource with the Specified Brand Name

    */
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    SetupLightsVC *setupLightsView = (SetupLightsVC *)[segue destinationViewController];
    setupLightsView.selectedThermostats = self.selectedThermostats;
    
}



@end
