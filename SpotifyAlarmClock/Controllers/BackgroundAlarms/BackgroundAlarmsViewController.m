//
//  BackgroundAlarmsViewController.m
//  Alarm Clock
//
//  Created by Niels Vroegindeweij on 18-11-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "BackgroundAlarmsViewController.h"
#import "AlarmHelper.h"

@interface BackgroundAlarmsViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *swBackgroundAlarms;
@property (weak, nonatomic) IBOutlet UITextView *txtBackgroundAlarms;
- (IBAction)backgroundAlarmsSwitchChanged:(UISwitch *)sender;

@end

@implementation BackgroundAlarmsViewController
@synthesize swBackgroundAlarms;
@synthesize txtBackgroundAlarms;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [txtBackgroundAlarms setText:@"When this app is not running in the foreground, the app is unable to play Spotify songs for your alarm. However, you will still receive notifications and hear an alarm sound when you enabled Background Alarms.\n\nMake sure your device is not in Silent/Do-Not-Disturb mode or on low volume to hear the Background Alarm.\n\nBackground Alarms will only work when you allowed the app to send notifications. This configuration can be changed in the Settings app."];
    [txtBackgroundAlarms setTextColor:[UIColor grayColor]];
    [txtBackgroundAlarms setFont:[UIFont systemFontOfSize:14]];
    [txtBackgroundAlarms setTextContainerInset:UIEdgeInsetsMake(0, 10, 0, 10)];
    
    [swBackgroundAlarms setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"BackgroundAlarm"]];
}



- (IBAction)backgroundAlarmsSwitchChanged:(UISwitch *)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:@"BackgroundAlarm"];
    
    [AlarmHelper configureBackgroundAlarms];
}
@end
