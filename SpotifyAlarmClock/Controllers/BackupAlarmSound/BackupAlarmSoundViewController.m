//
//  BackupAlarmSoundViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 22-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "BackupAlarmSoundViewController.h"
#import "Tools.h"
@import AVFoundation;

@interface BackupAlarmSoundViewController ()

@property (nonatomic, strong) NSUserDefaults * userDefaults;
@property (nonatomic, strong) AVAudioPlayer * audioPlayer;
@property (nonatomic, assign) bool isPlaying;

- (void) playAudioForSound:(NSUInteger)selectedSound;

@end

@implementation BackupAlarmSoundViewController
@synthesize userDefaults;
@synthesize audioPlayer;

- (void)viewDidLoad {
    [super viewDidLoad];

    self.userDefaults = [NSUserDefaults standardUserDefaults];
    self.isPlaying = NO;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Set checkmark on selected cell
    NSUInteger selectedSound = [userDefaults integerForKey:@"BackupAlarmSound"];
    [[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedSound inSection:0]] setAccessoryType:UITableViewCellAccessoryCheckmark];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.isPlaying)
    {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
    } 
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
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    //Set/unset checkmark
    [currentSoundCell setAccessoryType:UITableViewCellAccessoryNone];
    [selectedCell  setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    //Play sound
    [self playAudioForSound:[indexPath row]];
    
    //Save setting
    [userDefaults setInteger:[indexPath row] forKey:@"BackupAlarmSound"];
    [userDefaults synchronize];
    
}

- (void) playAudioForSound:(NSUInteger)selectedSound
{
    //Stop playing current sound
    if (self.isPlaying)
    {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
        self.isPlaying = NO;
        
        //Don't start new song, when selected sound didn't change
        NSUInteger currentSound = [userDefaults integerForKey:@"BackupAlarmSound"];
        if(currentSound == selectedSound)
            return;
    }
    

    //Play new sound
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:[Tools dataForAlarmBackupSound:selectedSound] fileTypeHint:AVFileTypeMPEGLayer3 error:&error];
    
    //Check if init successful
    if(error != nil)
    {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not start backup sound to listen!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
        NSLog(@"Could not start backup sound, error: %@", error);
        
        return;
    }
    
    [self.audioPlayer play];
    self.isPlaying = YES;
}

@end
