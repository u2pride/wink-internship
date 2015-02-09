//
//  SetupThermostatVC.m
//  WinkInternship
//
//  Created by Alex Ryan on 2/5/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import "BrandOfWink.h"
#import "BrandTableCellForThermometers.h"
#import "SetupLightsVC.h"
#import "SetupThermostatVC.h"
#import "ThermostatInWink.h"
#import <CoreImage/CoreImage.h>

static NSString * const BaseAPIString = @"https://winkapi.quirky.com/";
static NSString * const kAccessToken = @"access_token";
static NSString * const kRefreshToken = @"refresh_token";

@interface SetupThermostatVC ()

@property (weak, nonatomic) IBOutlet UITableView *thermostatTable;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UILabel *resultTextLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;

@property (nonatomic, strong) NSMutableArray *thermostatBrands;

@property (nonatomic, strong) NSMutableArray *allThermostats;
@property (nonatomic, strong) NSMutableArray *selectedThermostats;
@property (nonatomic, strong) NSIndexPath *indexPathSelected;


@end

@implementation SetupThermostatVC

@synthesize thermostatTable, nextButton, resultTextLabel, thermostatBrands, allThermostats, selectedThermostats, indexPathSelected, activitySpinner;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    //initialize arrays
    self.allThermostats = [[NSMutableArray alloc] init];
    self.selectedThermostats = [[NSMutableArray alloc] init];
    self.thermostatBrands = [[NSMutableArray alloc] init];

    self.activitySpinner.hidesWhenStopped = YES;
    
    //Create Brand Objects
    BrandOfWink *nest = [[BrandOfWink alloc] initWithBrandName:@"Nest" withBrandImage:[UIImage imageNamed:@"Nest"] withManufacturer:@"nest"];
    BrandOfWink *quirky = [[BrandOfWink alloc] initWithBrandName:@"Quirky" withBrandImage:[UIImage imageNamed:@"Quirky"] withManufacturer:@"quirky"];
    BrandOfWink *honeywell = [[BrandOfWink alloc] initWithBrandName:@"Honeywell" withBrandImage:[UIImage imageNamed:@"Honeywell"] withManufacturer:@"honeywell"];
    
    [self.thermostatBrands addObject:nest];
    [self.thermostatBrands addObject:quirky];
    [self.thermostatBrands addObject:honeywell];
    
    
    //Adjustments to Navigation & Status Bar - Same Navigation Bar is used throughout the App, So Adjustments Only Needed Here
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [self.navigationItem setTitle:@"Setup Thermostat"];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0 green:0.722 blue:0.945 alpha:1];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.translucent = NO;

    
    //Adjustments to Views
    self.view.backgroundColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0];
    self.thermostatTable.layer.cornerRadius = 20;
    self.nextButton.layer.cornerRadius = 15;
    self.nextButton.titleLabel.text = @"Next";
    self.nextButton.backgroundColor = [UIColor colorWithRed:0 green:0.722 blue:0.945 alpha:1];
    self.resultTextLabel.text = @"Select a Brand";

}



#pragma mark - UITableView Delegate/DataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *stringIdentifier = @"BrandCell";
    
    BrandTableCellForThermometers *brandCell = [tableView dequeueReusableCellWithIdentifier:stringIdentifier forIndexPath:indexPath];
    
    BrandOfWink *currentBrand = [self.thermostatBrands objectAtIndex:indexPath.row];
    
    if (brandCell) {
        brandCell.brandImageView.image = currentBrand.brandImage;
    }
    
    return brandCell;
}

- (NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.thermostatBrands count];
    
}


// Method Description
// Upon selecting a row, the app grabs the stored tokens and calls the api for all of the thermostats owned by the user.
// Once the thermostats are grabbed, the thermostats of the selected brand/manufacturer are stored.
// When the next button is pressed, the selected thermostats are sent to the next View Controller.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.activitySpinner startAnimating];
    
    BrandTableCellForThermometers *currentCell = (BrandTableCellForThermometers *)[tableView cellForRowAtIndexPath:indexPath];
    
    //Update the Accessory Views - Single Selection
    if (self.indexPathSelected) {
        BrandTableCellForThermometers *previousSelection = (BrandTableCellForThermometers *)[tableView cellForRowAtIndexPath:self.indexPathSelected];
        previousSelection.accessoryType = UITableViewCellAccessoryNone;
    }
    
    currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
    self.indexPathSelected = indexPath;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    //Call to the API using User Token to Find Light Resources

    NSString *accessToken = [userDefaults objectForKey:kAccessToken];
    NSString *valueForHTTPHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
    NSString *urlString = [NSString stringWithFormat:@"%@/users/me/thermostats", BaseAPIString];
    
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
                                          
                                          UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error Finding Thermostats" delegate:self cancelButtonTitle:@"done" otherButtonTitles: nil];
                                          
                                          [errorAlert show];
                                          
                                          return;
                                      } else {
                                          
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              [self resultsFromRequest:data];
                                          });
                                          
                                          
                                      }
                                    
                                  }];
    [task resume];

    
}


//Parsing Through Response for Thermostats
- (void)resultsFromRequest:(NSData *)data {
    
    
    NSError *errorJSON;
    NSMutableDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&errorJSON];
    
    NSArray *thermostats = [dictionary objectForKey:@"data"];
    
    int numberOfThermostats = 0;
    
    [self.selectedThermostats removeAllObjects];
    
    NSIndexPath *selectedPath = [self.thermostatTable indexPathForSelectedRow];
    BrandOfWink *selectedBrand = [self.thermostatBrands objectAtIndex:selectedPath.row];
    NSString *manufacturer = selectedBrand.manufacturerName;

    //For Each Thermostat Found - Create a new Thermostat Model Object and Add To Results Array
    for (NSDictionary *thermostat in thermostats) {
        
        ThermostatInWink *newThermostat = [[ThermostatInWink alloc] initWithThermostatID:thermostat[@"thermostat_id"] withName:thermostat[@"name"] withManufacturer:thermostat[@"device_manufacturer"]];
        
        [self.allThermostats addObject:newThermostat];
        
        //Request is For All Thermostats - Select Only Thermostats with the Selected Manufacturer
        if ([newThermostat.thermostatManufacturer isEqualToString:manufacturer]) {
            numberOfThermostats += 1;
            [self.selectedThermostats addObject:newThermostat];
        }
        
    }
    
    //Update View
    if (numberOfThermostats >= 1) {
        self.resultTextLabel.text = [NSString stringWithFormat:@"Found A Thermostat"];
    } else {
        self.resultTextLabel.text = [NSString stringWithFormat:@"No Thermostats Found"];
    }
    
    [self.activitySpinner stopAnimating];
        
    
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    //Pass Thermostats to Next View Controller
    SetupLightsVC *setupLightsView = (SetupLightsVC *)[segue destinationViewController];
    setupLightsView.selectedThermostats = self.selectedThermostats;
    
}




@end
