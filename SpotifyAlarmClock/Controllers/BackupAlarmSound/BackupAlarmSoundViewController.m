//
//  BackupAlarmSoundViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 22-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "BackupAlarmSoundViewController.h"
@import AVFoundation;

@interface BackupAlarmSoundViewController ()

@property (nonatomic, strong) NSUserDefaults * userDefaults;

@end

@implementation BackupAlarmSoundViewController
@synthesize userDefaults;

- (void)viewDidLoad {
    [super viewDidLoad];

    userDefaults = [NSUserDefaults standardUserDefaults];
    
    //self.backgroundMusicPlayer = [[AVAudioPlayer alloc] in];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Set checkmark on selected cell
    NSUInteger selectedSound = [userDefaults integerForKey:@"BackupAlarmSound"];
    [[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedSound inSection:0]] setAccessoryType:UITableViewCellAccessoryCheckmark];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger selectedSound = [userDefaults integerForKey:@"BackupAlarmSound"];
    UITableViewCell *currentSoundCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedSound inSection:0]];
    UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];

    //Set/unset checkmark
    [currentSoundCell setAccessoryType:UITableViewCellAccessoryNone];
    [selectedCell  setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    //Save setting
    [userDefaults setInteger:[indexPath row] forKey:@"BackupAlarmSound"];
    [userDefaults synchronize];
}

@end
