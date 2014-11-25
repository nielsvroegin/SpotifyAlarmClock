//
//  AddAlarmViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 16-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "AppDelegate.h"
#import "CocoaLibSpotify.h"
#import "Alarm.h"
#import "AlarmSong.h"
#import "AddAlarmViewController.h"
#import "OptionsSelectViewController.h"
#import "TextEditViewController.h"
#import "SongsViewController.h"
#import "Option.h"
#import "Tools.h"
#import "AlarmHelper.h"

@interface AddAlarmViewController ()

@property (nonatomic, strong) NSArray * repeatOptions;
@property (nonatomic, strong) NSOrderedSet * alarmSongs;
@property (weak, nonatomic) IBOutlet UILabel * lbRepeat;
@property (weak, nonatomic) IBOutlet UILabel * lbLabel;
@property (weak, nonatomic) IBOutlet UILabel *lbSongs;
@property (weak, nonatomic) IBOutlet UISwitch *snoozeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *shuffleSwitch;
@property (weak, nonatomic) IBOutlet UIDatePicker *timePicker;
@property (nonatomic, assign) bool songsChanged;


- (BOOL) isOptionSelected:(NSUInteger)index;
- (NSString *) repeatOptionsText;
- (NSString *)repeatOptionsToString;
- (void)repeatOptionsFromString:(NSString *)rpOptions;
- (void) playListRowSelected;

@end

@implementation AddAlarmViewController
@synthesize repeatOptions;
@synthesize lbLabel;
@synthesize lbRepeat;
@synthesize lbSongs;
@synthesize snoozeSwitch;
@synthesize shuffleSwitch;
@synthesize timePicker;
@synthesize songsChanged;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    self.timePicker.backgroundColor = [UIColor whiteColor];
    
    self.repeatOptions = [NSArray arrayWithObjects: [[Option alloc] initWithLabel:@"Every Monday" abbreviate:@"Mon" selected:FALSE],
                            [[Option alloc] initWithLabel:@"Every Tuesday" abbreviate:@"Tue" selected:FALSE],
                            [[Option alloc] initWithLabel:@"Every Wednesday" abbreviate:@"Wed" selected:FALSE],
                            [[Option alloc] initWithLabel:@"Every Thursday" abbreviate:@"Thu" selected:FALSE],
                            [[Option alloc] initWithLabel:@"Every Friday" abbreviate:@"Fri" selected:FALSE],
                            [[Option alloc] initWithLabel:@"Every Saturday" abbreviate:@"Sat" selected:FALSE],
                            [[Option alloc] initWithLabel:@"Every Sunday" abbreviate:@"Sun" selected:FALSE], nil];
    
    if(self.alarmData != nil)
    {
        [self setAlarmSongs:[self.alarmData.songs copy]];
        [self.lbSongs setText:[NSString stringWithFormat:@"%d Songs", [self.alarmData.songs count]]];
        [self repeatOptionsFromString:[self.alarmData repeat]];
        [self.lbRepeat setText:[self repeatOptionsText]];
        [self.lbLabel setText:[self.alarmData name]];
        [self.snoozeSwitch setOn:[[self.alarmData snooze] boolValue]];
        [self.shuffleSwitch setOn:[[self.alarmData shuffle] boolValue]];
        [self.timePicker setDate:[Tools dateForHour:[[self.alarmData hour] intValue] andMinute:[[self.alarmData minute] intValue]]];
        
        [self setTitle:@"Edit Alarm"];
    }
    else
        [self setTitle:@"Add Alarm"];
    
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)SaveAlarm
{
    /****** Get refs to Managed object context ******/
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSError *error;
    
    /****** Create new object if managed object not exists ******/
    if(self.alarmData == nil)
    {
        self.alarmData = [NSEntityDescription insertNewObjectForEntityForName:@"Alarm" inManagedObjectContext:context];
    }
    
    /****** Set new values ******/
    NSDateComponents *dateComponents = [Tools hourAndMinuteForDate:[self.timePicker date]];
    [self.alarmData setName:[self.lbLabel text]];
    [self.alarmData setRepeat:[self repeatOptionsToString]];
    [self.alarmData setSnooze:[NSNumber numberWithBool:[self.snoozeSwitch isOn]]];
    [self.alarmData setShuffle:[NSNumber numberWithBool:[self.shuffleSwitch isOn]]];
    [self.alarmData setHour:[NSNumber numberWithInt:[dateComponents hour]]];
    [self.alarmData setMinute:[NSNumber numberWithInt:[dateComponents minute]]];
    [self.alarmData setLastEdited:[NSDate date]];
    [self.alarmData setEnabled:[NSNumber numberWithBool:YES]];
    
    /***** Set Alarm Songs ******/
    if(songsChanged)
    {
        //Remove all
        for(AlarmSong *alarmSong in self.alarmData.songs)
            [context deleteObject:alarmSong];
        
        //Add all
        for(AlarmSong *alarmSong in self.alarmSongs)
            alarmSong.alarm = self.alarmData;
    }
   
    /****** Save alarmData object ******/
    if(![context save:&error])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not save Alarm!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil];
        [alert show];
        
        NSLog(@"Context save error: %@", error);
    }
    
    //Load new background alarms
    [AlarmHelper configureBackgroundAlarms];
}

- (NSString *)repeatOptionsToString
{
    NSString *repeatValue = @"";
    for(int i = 0; i < [self.repeatOptions count]; i++)
        if([self.repeatOptions[i] selected])
            repeatValue = [repeatValue stringByAppendingFormat:@"%d,", i];
    
    if([repeatValue length] > 0)
        repeatValue = [repeatValue substringToIndex:([repeatValue length]-1)];
    
    return repeatValue;
}

- (void)repeatOptionsFromString:(NSString *)rpOptions
{
    for(int i = 0; i < [self.repeatOptions count]; i++)
    {
        if(self.alarmData != nil && [[self.alarmData repeat] rangeOfString:[NSString stringWithFormat:@"%d", i]].location != NSNotFound )
            [[self.repeatOptions objectAtIndex:i] setSelected:YES];
        else
            [[self.repeatOptions objectAtIndex:i] setSelected:NO];
    }
}

#pragma mark - OptionsSelect delegate
- (void)optionValueChanged:(Option *) option
{
    [self.lbRepeat setText:[self repeatOptionsText]];
}

- (NSString *) repeatOptionsText
{
    NSString *repeatOptionsText = @"";
    
    //Create text
    if(![self isOptionSelected:0] && ![self isOptionSelected:1] && ![self isOptionSelected:2] && ![self isOptionSelected:3] && ![self isOptionSelected:4] && ![self isOptionSelected:5] && ![self isOptionSelected:6])
        repeatOptionsText = @"Never";
    if([self isOptionSelected:0] && [self isOptionSelected:1] && [self isOptionSelected:2] && [self isOptionSelected:3] && [self isOptionSelected:4] && [self isOptionSelected:5] && [self isOptionSelected:6])
        repeatOptionsText = @"Every day";
    else if([self isOptionSelected:0] && [self isOptionSelected:1] && [self isOptionSelected:2] && [self isOptionSelected:3] && [self isOptionSelected:4] && ![self isOptionSelected:5] && ![self isOptionSelected:6])
        repeatOptionsText = @"Weekdays";
    else if(![self isOptionSelected:0] && ![self isOptionSelected:1] && ![self isOptionSelected:2] && ![self isOptionSelected:3] && ![self isOptionSelected:4] && [self isOptionSelected:5] && [self isOptionSelected:6])
        repeatOptionsText = @"Weekends";
    else
        for(NSUInteger i = 0; i < [self.repeatOptions count]; i++)
            if([self isOptionSelected:i])
                repeatOptionsText = [repeatOptionsText stringByAppendingFormat:@" %@", [[self.repeatOptions objectAtIndex:i] abbreviate]];
    
    return repeatOptionsText;
}

- (BOOL) isOptionSelected:(NSUInteger)index
{
    Option * option = [self.repeatOptions objectAtIndex:index];
    return  option.selected;
}

#pragma mark - TextEdit delegate
- (void) textEditChanged:(TextEditViewController *)textEdit value:(NSString *)newValue
{
    [self.lbLabel setText:newValue];
}

#pragma mark - Songs delegate
- (void) selectedSongsChanged:(NSArray*)tracks
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSMutableOrderedSet *songs = [[NSMutableOrderedSet alloc] init];
    
    for(SPTrack *track in tracks)
    {
        AlarmSong *alarmSong = [NSEntityDescription insertNewObjectForEntityForName:@"AlarmSong" inManagedObjectContext:context];
        alarmSong.spotifyUrl = [track.spotifyURL absoluteString];
        
        [songs addObject:alarmSong];
    }
    
    self.alarmSongs = songs;
    [self.lbSongs setText:[NSString stringWithFormat:@"%d Songs", [songs count]]];
    
    self.songsChanged = YES;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if([indexPath row] == 1)
        [self playListRowSelected];
}


- (void) playListRowSelected
{
    //Check if user uses Spotify
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"SpotifyUsername"] == nil || [[NSUserDefaults standardUserDefaults] boolForKey:@"UseAlarmClockWithoutSpotify"])
    {
        //User doesn't use spotify, let him choose to enable it or cancel
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Spotify Required"
                                                       message:@"Your Spotify account isn't linked with this alarm clock yet. This is mandatory to select Spotify songs for your alarm playlist. Please choose how to proceed?"
                                                      delegate:self
                                             cancelButtonTitle:@"Cancel"
                                             otherButtonTitles:@"Log in to Spotify",nil];
        [alert show];
    }
    else
        [self performSegueWithIdentifier:@"playlistSegue" sender:self];
}

#pragma mark - Alert view delegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == [alertView firstOtherButtonIndex])
        [self performSegueWithIdentifier:@"resetLoginSegue" sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"repeatOptionsSelect"])
    {
        OptionsSelectViewController* vw = [segue destinationViewController];
        [vw setTitle:@"Repeat"];
        [vw setDelegate:self];
        [vw setOptions:[self repeatOptions]];
    }
    else if([[segue identifier] isEqualToString:@"labelTextEdit"])
    {
        TextEditViewController* vw = [segue destinationViewController];
        [vw setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [vw setTitle:@"Label"];
        [vw setDelegate:self];
        [vw setText:[self.lbLabel text]];
    }
    else if([[segue identifier] isEqualToString:@"playlistSegue"])
    {
        SongsViewController* vw = [segue destinationViewController];
        [vw setDelegate:self];
        [vw setAlarmSongs:[self alarmSongs]];
    }
    else if([[segue identifier] isEqualToString:@"saveAlarm"])
    {
        [self SaveAlarm];
    }
    else if([[segue identifier] isEqualToString:@"resetLoginSegue"])
    {
        [[SPSession sharedSession] logout:nil];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SpotifyUsername"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SpotifyPassword"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"UseAlarmClockWithoutSpotify"];
    }
}
@end
