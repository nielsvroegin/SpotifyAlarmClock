//
//  SettingsViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 24-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@property (nonatomic, strong) NSUserDefaults * userDefaults;

@property (weak, nonatomic) IBOutlet UISwitch *swBlinkSecondsMarker;
@property (weak, nonatomic) IBOutlet UISwitch *swShowBackgroundGlow;


- (IBAction)blinkSecondsMarkerSettingChanged:(id)sender;
- (IBAction)showBackgroundGlowSettingChanged:(id)sender;

@end

@implementation SettingsViewController
@synthesize userDefaults;
@synthesize swBlinkSecondsMarker;
@synthesize swShowBackgroundGlow;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.userDefaults = [NSUserDefaults standardUserDefaults];

    //Apply settings in view
    [swBlinkSecondsMarker setOn:[userDefaults boolForKey:@"BlinkSecondsMarker"]];
    [swShowBackgroundGlow setOn:[userDefaults boolForKey:@"ShowBackgroundGlow"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)blinkSecondsMarkerSettingChanged:(id)sender
{
    [userDefaults setBool:[swBlinkSecondsMarker isOn] forKey:@"BlinkSecondsMarker"];
    [userDefaults synchronize];
}

- (IBAction)showBackgroundGlowSettingChanged:(id)sender
{
    [userDefaults setBool:[swShowBackgroundGlow isOn] forKey:@"ShowBackgroundGlow"];
    [userDefaults synchronize];
}
@end
