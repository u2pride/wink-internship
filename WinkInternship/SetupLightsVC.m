//
//  SetupLightsVC.m
//  WinkInternship
//
//  Created by Alex Ryan on 2/5/15.
//  Copyright (c) 2015 U2PrideLabs. All rights reserved.
//

#import "BrandOfWink.h"
#import "BrandTableCellForLights.h"
#import "ControlRobotVC.h"
#import "LightInWink.h"
#import "SetupLightsVC.h"

static NSString * const BaseAPIString = @"https://winkapi.quirky.com/";
static NSString * const kAccessToken = @"access_token";
static NSString * const kRefreshToken = @"refresh_token";

@interface SetupLightsVC ()

@property (weak, nonatomic) IBOutlet UITableView *lightBrandsTable;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UILabel *lightsTextLabel;

@property (nonatomic, strong) NSMutableArray *lightBrands;

@property (nonatomic, strong) NSMutableArray *lightsFound;
@property (nonatomic, strong) NSMutableArray *selectedLights;
@property (nonatomic, strong) NSIndexPath *indexPathSelected;


@end

@implementation SetupLightsVC

@synthesize lightBrandsTable, nextButton, lightsTextLabel, lightBrands, lightsFound, selectedLights, indexPathSelected, selectedThermostats;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //initialize arrays
    self.lightsFound = [[NSMutableArray alloc] init];
    self.selectedLights = [[NSMutableArray alloc] init];
    self.lightBrands = [[NSMutableArray alloc] init];

    
    //Create Brand Objects for Table View
    BrandOfWink *philips = [[BrandOfWink alloc] initWithBrandName:@"Philips" withBrandImage:[UIImage imageNamed:@"Philips"] withManufacturer:@"philips"];
    BrandOfWink *ge = [[BrandOfWink alloc] initWithBrandName:@"GE" withBrandImage:[UIImage imageNamed:@"GE"] withManufacturer:@"ge"];
    BrandOfWink *tcp = [[BrandOfWink alloc] initWithBrandName:@"TCP" withBrandImage:[UIImage imageNamed:@"TCP"] withManufacturer:@"tcp"];
    BrandOfWink *cree = [[BrandOfWink alloc] initWithBrandName:@"CREE" withBrandImage:[UIImage imageNamed:@"CREE"] withManufacturer:@"cree"];
    
    [self.lightBrands addObject:philips];
    [self.lightBrands addObject:ge];
    [self.lightBrands addObject:tcp];
    [self.lightBrands addObject:cree];
    
    //Adjust Navigation Bar Title
    [self.navigationItem setTitle:@"Setup Lights"];
    
    //Adjustments to View
    self.view.backgroundColor = [UIColor colorWithRed:0.965 green:0.965 blue:0.965 alpha:1.0];
    self.lightBrandsTable.layer.cornerRadius = 20;
    self.nextButton.layer.cornerRadius = 15;
    self.nextButton.titleLabel.text = @"Next";
    self.nextButton.backgroundColor = [UIColor colorWithRed:0 green:0.722 blue:0.945 alpha:1];
    self.lightsTextLabel.text = @"Select A Brand";

}


#pragma mark - UITableView Delegate/DataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = @"BrandCellForLights";
    
    BrandOfWink *currentBrand = [self.lightBrands objectAtIndex:indexPath.row];
    
    BrandTableCellForLights *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (cell) {
        cell.lightBrandImageView.image = currentBrand.brandImage;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.lightBrands count];
}


// Method Description
// Upon selecting a row, the app grabs the stored tokens and calls the api for all of the lights owned by the user.
// Once the lights are grabbed, the lights of the selected brand/manufacturer are stored.
// When the next button is pressed, the selected lights are sent to the next View Controller.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BrandTableCellForLights *currentCell = (BrandTableCellForLights *)[tableView cellForRowAtIndexPath:indexPath];
    
    //Update the Accessory Views - Single Selection
    if (self.indexPathSelected) {
        BrandTableCellForLights *previousSelection = (BrandTableCellForLights *)[tableView cellForRowAtIndexPath:self.indexPathSelected];
        previousSelection.accessoryType = UITableViewCellAccessoryNone;
    }
    
    currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
    self.indexPathSelected = indexPath;
    
    //Grab the tokens
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *accessToken = [userDefaults objectForKey:kAccessToken];
    NSString *valueForHTTPHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
    NSString *urlString = [NSString stringWithFormat:@"%@/users/me/light_bulbs", BaseAPIString];

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

                                        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error Finding Lights" delegate:self cancelButtonTitle:@"done" otherButtonTitles: nil];
                    
                                        [errorAlert show];
                                          
                                          return;
                                      
                                      } else {
                                          
                                          if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                              NSLog(@"Response HTTP Status code: %ld\n", (long)[(NSHTTPURLResponse *)response statusCode]);
                                              NSLog(@"Response HTTP Headers:\n%@\n", [(NSHTTPURLResponse *)response allHeaderFields]);
                                          }
                                          
                                          NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                          NSLog(@"Response Body:\n%@\n", body);
                                          
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              [self resultsFromRequest:data];
                                          });

                                      }
                                      
                                      
                                  }];
    [task resume];
    

    
    
}

//Parsing Through Response for Lights
- (void)resultsFromRequest:(NSData *)data {
    
    NSError *errorJSON;
    NSMutableDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&errorJSON];
    
    NSArray *allLights = [dictionary objectForKey:@"data"];
    
    int numberOfLights = 0;
    
    [self.selectedLights removeAllObjects];
    
    NSIndexPath *selectedPath = [self.lightBrandsTable indexPathForSelectedRow];
    BrandOfWink *selectedBrand = [self.lightBrands objectAtIndex:selectedPath.row];
    NSString *manufacturer = selectedBrand.manufacturerName;
    
    for (NSDictionary *light in allLights) {
        
        NSLog(@"light ID: %@", light[@"light_bulb_id"]);
        NSLog(@"device manu: %@", light[@"device_manufacturer"]);
        
        LightInWink *newLight = [[LightInWink alloc] initWithLightID:light[@"light_bulb_id"] withLightName:light[@"name"] withManufacturer:light[@"device_manufacturer"]];
        
        [self.lightsFound addObject:newLight];
        
        //Request is For All Lights - Select Only Lights with the Selected Manufacturer
        if ([newLight.lightManufacturer isEqualToString:manufacturer]) {
            numberOfLights += 1;
            [self.selectedLights addObject:newLight];
        }
        
        
        
    }
    
    
    //Update View
    if (numberOfLights >= 1) {
        self.lightsTextLabel.text = [NSString stringWithFormat:@"Found %d Lights", numberOfLights];
    } else {
        self.lightsTextLabel.text = [NSString stringWithFormat:@"No Lights Found"];
    }


}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    ControlRobotVC *controlViewController = (ControlRobotVC *)[segue destinationViewController];
    //Pass Lights and Thermostats to Control View
    controlViewController.userLights = self.selectedLights;
    controlViewController.userThermostats = self.selectedThermostats;
    
}



/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */



/*
+ (NSURLSessionDataTask *)fromURL:(NSString *)url completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    
    NSURL *urlForRequest = [NSURL URLWithString:url];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:urlForRequest];
    
    //Grab the tokens
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *accessToken = [userDefaults objectForKey:kAccessToken];
    NSString *valueForHTTPHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
    
    
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:valueForHTTPHeader forHTTPHeaderField:@"Authorization"];

    NSURLSession *session = [NSURLSession sharedSession];

    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completionHandler)
            completionHandler(data, response, error);
    }];
    
    [dataTask resume];
    
    return dataTask;
}

*/

//Refresh SelectedLights
//self.selectedLights = nil;

//self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];




@end
