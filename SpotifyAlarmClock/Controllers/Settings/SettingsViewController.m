//
//  SettingsViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 24-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "SettingsViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "TextEditViewController.h"
#import "Tools.h"

@import AVFoundation;

@interface SettingsViewController ()

@property (nonatomic, strong) NSUserDefaults * userDefaults;

@property (weak, nonatomic) IBOutlet UISwitch *swBlinkSecondsMarker;
@property (weak, nonatomic) IBOutlet UISwitch *swShowBackgroundGlow;
@property (weak, nonatomic) IBOutlet UISlider *slMaxVolume;
@property (weak, nonatomic) IBOutlet UISlider *slBrightness;
@property (weak, nonatomic) IBOutlet UILabel *lbSpotifyUsername;
@property (weak, nonatomic) IBOutlet UILabel *lbSpotifyPassword;

- (IBAction)blinkSecondsMarkerSettingChanged:(id)sender;
- (IBAction)showBackgroundGlowSettingChanged:(id)sender;
- (IBAction)maxVolumeSettingChanged:(id)sender;
- (IBAction)brightnessSettingChanged:(id)sender;


@end

@implementation SettingsViewController
@synthesize userDefaults;
@synthesize swBlinkSecondsMarker;
@synthesize swShowBackgroundGlow;
@synthesize slMaxVolume;
@synthesize slBrightness;
@synthesize lbSpotifyUsername;
@synthesize lbSpotifyPassword;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.userDefaults = [NSUserDefaults standardUserDefaults];
   

    //Apply settings in view
    [swBlinkSecondsMarker setOn:[userDefaults boolForKey:@"BlinkSecondsMarker"]];
    [swShowBackgroundGlow setOn:[userDefaults boolForKey:@"ShowBackgroundGlow"]];
    [slMaxVolume setValue:[userDefaults floatForKey:@"MaxVolume"]];
    [slBrightness setValue:[userDefaults floatForKey:@"Brightness"]];
    
    if([[userDefaults stringForKey:@"SpotifyUsername"] length] > 0)
        [lbSpotifyUsername setText:[userDefaults stringForKey:@"SpotifyUsername"]];
    else
        [lbSpotifyUsername setText:@"Not specified"];
    
    if([[userDefaults stringForKey:@"SpotifyPassword"] length] > 0)
        [lbSpotifyPassword setText:[Tools dottedString:[userDefaults stringForKey:@"SpotifyPassword"]]];
    else
        [lbSpotifyPassword setText:@"Not specified"];
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

- (IBAction)maxVolumeSettingChanged:(id)sender
{
    [userDefaults setFloat:[slMaxVolume value] forKey:@"MaxVolume"];
    [userDefaults synchronize];
}

- (IBAction)brightnessSettingChanged:(id)sender
{
    [[UIScreen mainScreen] setBrightness:[slBrightness value]];
    
    [userDefaults setFloat:[slBrightness value] forKey:@"Brightness"];
    [userDefaults synchronize];
}

#pragma mark - Text edit delegate method(s)

- (void) textEditChanged:(TextEditViewController *)textEdit value:(NSString *)newValue
{
    if([textEdit tag] == 1) //Username
    {
        [userDefaults setObject:newValue forKey:@"SpotifyUsername"];
        if([newValue length] > 0)
            [lbSpotifyUsername setText:newValue];
        else
            [lbSpotifyUsername setText:@"Not specified"];
            
    }
    else if([textEdit tag] == 2) //Password
    {
        [userDefaults setObject:newValue forKey:@"SpotifyPassword"];
        if([newValue length] > 0)
            [lbSpotifyPassword setText:[Tools dottedString:newValue]];
        else
            [lbSpotifyPassword setText:@"Not specified"];
    }
        
    [userDefaults synchronize];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"spotifyUsernameSegue"])
    {
        TextEditViewController * vw = [segue destinationViewController];
        [vw setTag:1];
        [vw setTitle:@"Spotify Username"];
        [vw setText:[userDefaults stringForKey:@"SpotifyUsername"]];
        [vw setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [vw setDelegate:self];
    }
    else if([[segue identifier] isEqualToString:@"spotifyPasswordSegue"])
    {
        TextEditViewController * vw = [segue destinationViewController];
        [vw setTag:2];
        [vw setTitle:@"Spotify Password"];
        [vw setText:[userDefaults stringForKey:@"SpotifyPassword"]];
        [vw setSecureTextEntry:YES];
        [vw setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [vw setDelegate:self];
    }
    
}

@end
