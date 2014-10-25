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
#import "CocoaLibSpotify.h"

@import AVFoundation;

@interface SettingsViewController ()

@property (nonatomic, strong) NSUserDefaults * userDefaults;
@property (nonatomic, assign) BOOL spotifyCredentialsChanged;

@property (weak, nonatomic) IBOutlet UISwitch *swBlinkSecondsMarker;
@property (weak, nonatomic) IBOutlet UISwitch *swShowBackgroundGlow;
@property (weak, nonatomic) IBOutlet UISlider *slMaxVolume;
@property (weak, nonatomic) IBOutlet UISlider *slBrightness;
@property (weak, nonatomic) IBOutlet UILabel *lbSpotifyUsername;
@property (weak, nonatomic) IBOutlet UILabel *lbSpotifyPassword;
@property (weak, nonatomic) IBOutlet UILabel *lbSpotifyConnectionState;

- (IBAction)blinkSecondsMarkerSettingChanged:(id)sender;
- (IBAction)showBackgroundGlowSettingChanged:(id)sender;
- (IBAction)maxVolumeSettingChanged:(id)sender;
- (IBAction)brightnessSettingChanged:(id)sender;
- (void) updateSpotifyConnectionState;

@end

@implementation SettingsViewController
@synthesize userDefaults;
@synthesize swBlinkSecondsMarker;
@synthesize swShowBackgroundGlow;
@synthesize slMaxVolume;
@synthesize slBrightness;
@synthesize lbSpotifyUsername;
@synthesize lbSpotifyPassword;
@synthesize spotifyCredentialsChanged;

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

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Observe spotify connection state
    [[SPSession sharedSession] addObserver:self forKeyPath:@"connectionState" options:0 context:NULL];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[SPSession sharedSession] removeObserver:self forKeyPath:@"connectionState"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqual:@"connectionState"])
        [self updateSpotifyConnectionState];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Re-login when sptofy credentials changed
    if(spotifyCredentialsChanged)
    {
        [[SPSession sharedSession] logout:^{
            [[SPSession sharedSession] attemptLoginWithUserName:[userDefaults objectForKey:@"SpotifyUsername"] password:[userDefaults objectForKey:@"SpotifyPassword"]];
        }];
        spotifyCredentialsChanged =  NO;
    }
    
    [self updateSpotifyConnectionState];
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

- (void) updateSpotifyConnectionState
{
    switch ([[SPSession sharedSession] connectionState])
    {
        case SP_CONNECTION_STATE_OFFLINE:
            self.lbSpotifyConnectionState.text = @"Offline";
            self.lbSpotifyConnectionState.textColor = [UIColor orangeColor];
            break;
        case SP_CONNECTION_STATE_DISCONNECTED:
            self.lbSpotifyConnectionState.text = @"Disconnected";
            self.lbSpotifyConnectionState.textColor = [UIColor orangeColor];
            break;
        case SP_CONNECTION_STATE_LOGGED_IN:
            self.lbSpotifyConnectionState.text = @"Online";
            self.lbSpotifyConnectionState.textColor = [UIColor colorWithRed:(24 / 255.0) green:(109 / 255.0) blue:(39 / 255.0) alpha:1];
            break;
        case SP_CONNECTION_STATE_LOGGED_OUT:
            self.lbSpotifyConnectionState.text = @"Logged Out";
            self.lbSpotifyConnectionState.textColor = [UIColor redColor];
            break;
        case SP_CONNECTION_STATE_UNDEFINED:
            self.lbSpotifyConnectionState.text = @"Unknown";
            self.lbSpotifyConnectionState.textColor = [UIColor orangeColor];
            break;
        default:
            self.lbSpotifyConnectionState.text = @"Unknown";
            self.lbSpotifyConnectionState.textColor = [UIColor orangeColor];
            break;
    }
}


#pragma mark - Text edit delegate method(s)

- (void) textEditChanged:(TextEditViewController *)textEdit value:(NSString *)newValue
{
    if([textEdit tag] == 1 && ![newValue isEqualToString:[userDefaults objectForKey:@"SpotifyUsername"]]) //Username
    {
        [userDefaults setObject:newValue forKey:@"SpotifyUsername"];
        if([newValue length] > 0)
            [lbSpotifyUsername setText:newValue];
        else
            [lbSpotifyUsername setText:@"Not specified"];
        
        spotifyCredentialsChanged = YES;
    }
    else if([textEdit tag] == 2 && ![newValue isEqualToString:[userDefaults objectForKey:@"SpotifyPassword"]]) //Password
    {
        [userDefaults setObject:newValue forKey:@"SpotifyPassword"];
        if([newValue length] > 0)
            [lbSpotifyPassword setText:[Tools dottedString:newValue]];
        else
            [lbSpotifyPassword setText:@"Not specified"];
        
        spotifyCredentialsChanged = YES;
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
