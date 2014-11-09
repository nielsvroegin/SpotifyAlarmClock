//
//  ClockViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 17-09-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ClockViewController.h"
#import "Alarm.h"
#import "AlarmSong.h"
#import "BackgroundGlow.h"
#import "NextAlarm.h"
#import "Tools.h"
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"

@import AVFoundation;

@interface ClockViewController ()

@property (nonatomic, assign) bool showColon;
@property (nonatomic, assign) bool loginChecked;
@property (nonatomic, assign) bool isPerformingAlarm;
@property (nonatomic, assign) Alarm * performingAlarm;
@property (nonatomic, strong) NextAlarm * nextAlarm;
@property (nonatomic, strong) NSMutableArray * songList;
@property (nonatomic, strong) NSDate * snoozeDate;
@property (nonatomic, strong) SPPlaybackManager * playBackManager;
@property (nonatomic, strong) AVAudioPlayer * audioPlayer;
@property (nonatomic, strong) NSUserDefaults * userDefaults;
@property (nonatomic, assign) float systemVolume;
@property (nonatomic, assign) NSUInteger songPlayTryCount;
@property (nonatomic, strong) NSMutableArray * backgroundTapGestures;

@property (weak, nonatomic) IBOutlet UILabel *spotifyConnectionState;
@property (weak, nonatomic) IBOutlet UILabel *hour;
@property (weak, nonatomic) IBOutlet UILabel *colon;
@property (weak, nonatomic) IBOutlet UILabel *minutes;
@property (weak, nonatomic) IBOutlet BackgroundGlow *backgroundGlow;
@property (weak, nonatomic) IBOutlet UILabel *lbDate;
@property (weak, nonatomic) IBOutlet UILabel *lbNextAlarm;
@property (weak, nonatomic) IBOutlet UIImageView *miniAlarmImage;
@property (weak, nonatomic) IBOutlet UIButton *btStopAlarm;
@property (weak, nonatomic) IBOutlet UIButton *btSnoozeAlarm;

@property (weak, nonatomic) IBOutlet UIView *topBarAlarm;
@property (weak, nonatomic) IBOutlet UIView *bottomBarAlarm;
@property (weak, nonatomic) IBOutlet UIView *alarmBackground;


- (void) updateSpotifyConnectionState;
- (void) updateClock;
- (void) updateClockAlarm;
- (void)backgroundTap;
- (IBAction)unwindToClock:(UIStoryboardSegue *)unwindSegue;
- (void) applyGlow:(UILabel*)label;
- (void)applyBackgroundTapRecursive:(UIView *)vw;
- (void) performAlarm:(Alarm *)alarm;
- (IBAction) stopAlarm;
- (IBAction) snoozeAlarm;
- (void) playSong;
- (void) playBackupAlarmSound;
- (void)enableTapGestures:(bool)enabled;
- (void) stopAlarmConfirmed;


@end

@implementation ClockViewController
@synthesize spotifyConnectionState;
@synthesize isPerformingAlarm;
@synthesize performingAlarm;
@synthesize hour;
@synthesize colon;
@synthesize minutes;
@synthesize backgroundGlow;
@synthesize showColon;
@synthesize loginChecked;
@synthesize lbDate;
@synthesize nextAlarm;
@synthesize miniAlarmImage;
@synthesize alarmBackground;
@synthesize topBarAlarm;
@synthesize bottomBarAlarm;
@synthesize songList;
@synthesize snoozeDate;
@synthesize playBackManager;
@synthesize audioPlayer;
@synthesize userDefaults;
@synthesize songPlayTryCount;
@synthesize btStopAlarm;
@synthesize btSnoozeAlarm;
@synthesize backgroundTapGestures;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)backgroundTap
{
    [self performSegueWithIdentifier:@"settingsSegue" sender:nil];
}

- (IBAction)unwindToClock:(UIStoryboardSegue *)unwindSegue { }

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.backgroundTapGestures = [[NSMutableArray alloc] init];
    
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    
    //Receive notification for significant time change/Locale change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timeChangedSignificant) name:UIApplicationSignificantTimeChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timeChangedSignificant) name:NSCurrentLocaleDidChangeNotification object:nil];
        
    //Register all views for background tap
    [self applyBackgroundTapRecursive:self.view];
    
    //Time digits glow
    [self applyGlow:hour];
    [self applyGlow:colon];
    [self applyGlow:minutes];
    
    //Create gadient for alarm background
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:(22.0/255.0) green:(107.0 / 255.0) blue:(47.0 / 255.0) alpha:1] CGColor], (id)[[UIColor colorWithRed:(27.0/255.0) green:(134.0 / 255.0) blue:(54.0 / 255.0) alpha:1] CGColor], nil];
    [alarmBackground.layer insertSublayer:gradient atIndex:0];
    
    //Set timer to update clock
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    
    //Init playbackmanager
    playBackManager = [SPPlaybackManager sharedPlaybackManager];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Set delegates
    [[SPSession sharedSession] setDelegate:self];
    [playBackManager setDelegate:self];
    
    //Update connection state
    [self updateSpotifyConnectionState];
    
    //Observe spotify connection state
    [[SPSession sharedSession] addObserver:self forKeyPath:@"connectionState" options:0 context:NULL];
    
    //Determine next alarm
    nextAlarm = [NextAlarm provide];
    
    //Update clock
    [self updateClock];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Keep app awake
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    //Check if need to login
    NSString * spotifyUsername = [userDefaults objectForKey:@"SpotifyUsername"];
    NSString * spotifyPassword = [userDefaults objectForKey:@"SpotifyPassword"];
    BOOL useAlarmClockWithoutSpotify = [userDefaults boolForKey:@"UseAlarmClockWithoutSpotify"];
    
    if(!useAlarmClockWithoutSpotify && (spotifyUsername == nil || spotifyPassword == nil || [spotifyUsername length] == 0 || [spotifyPassword length] == 0))
        [self performSegueWithIdentifier:@"SpotifyLoginSegue" sender:self];
    else
    {
        //Check for AlarmClock foreground warning
        if(![userDefaults boolForKey:@"alarmClockForegroundWarningDisplayed"])
        {
            [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"The Alarm Clock must be running in foreground to perform an alarm. Please remember to leave the app open in this clock view when you go to bed!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
            
            [userDefaults setBool:YES forKey:@"alarmClockForegroundWarningDisplayed"];
        }
    }
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[SPSession sharedSession] removeObserver:self forKeyPath:@"connectionState"];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // resize your layers based on the view’s new bounds
    [[[self.alarmBackground.layer sublayers] objectAtIndex:0] setFrame:self.view.bounds];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqual:@"connectionState"])
    {
        [self updateSpotifyConnectionState];
     
        if(performingAlarm && [[SPSession sharedSession] connectionState] != SP_CONNECTION_STATE_LOGGED_IN)
            [self playBackupAlarmSound];
    }
}

- (void) applyGlow:(UILabel*)label
{
    label.layer.shadowColor = [[UIColor yellowColor] CGColor];
    label.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    label.layer.shadowRadius = 4.0;
    label.layer.shadowOpacity = 0.3;
    label.layer.masksToBounds = NO;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)applyBackgroundTapRecursive:(UIView *)vw
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap)];
    [self.backgroundTapGestures addObject:tapGesture];
    
    vw.userInteractionEnabled = YES;
    [vw addGestureRecognizer:tapGesture];
    for(UIView* subView in [vw subviews])
    {
        if(subView != btStopAlarm && subView != btSnoozeAlarm)
            [self applyBackgroundTapRecursive:subView];
    }
}

- (void)enableTapGestures:(bool)enabled
{
    for(UITapGestureRecognizer *tapGesture in self.backgroundTapGestures)
        [tapGesture setEnabled:enabled];
}

- (void) timeChangedSignificant
{
    self.nextAlarm = [NextAlarm provide];
    [self updateClock];
}

- (void) performAlarm:(Alarm *)alarm
{
    isPerformingAlarm = true;
    performingAlarm = alarm;
    snoozeDate = nil;
    songPlayTryCount = 0;
    
    //Show ClockAlarm
    self.topBarAlarm.hidden = NO;
    self.topBarAlarm.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
    self.topBarAlarm.alpha = 0;
    
    if([[alarm snooze] boolValue])
    {
        self.bottomBarAlarm.hidden = NO;
        self.bottomBarAlarm.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
        self.bottomBarAlarm.alpha = 0;
    }

    
    [UIView animateWithDuration:0.3 animations:^() {
        if([[alarm snooze] boolValue])
            self.bottomBarAlarm.alpha = 1;
        
        self.topBarAlarm.alpha = 1;
    }];
    
    //Set volumes and remember volumes
    self.systemVolume = [Tools getSystemVolume];
    [playBackManager setVolume:0];
    [Tools setSystemVolume:[userDefaults floatForKey:@"MaxVolume"]];
    
    //Disable background tap
    [self enableTapGestures:NO];
    
    //Disable alarm in case repeat is never
    if(performingAlarm.repeat == nil || [performingAlarm.repeat length] == 0)
    {
        /****** Get refs to Managed object context ******/
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        NSError *error;
        
        [performingAlarm setEnabled:[NSNumber numberWithBool:NO]];
        
        /****** Save alarmData object ******/
        if(![context save:&error])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not disable non-repeating alarm!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil];
            [alert show];
            
            NSLog(@"Context save error: %@", error);
        }
    }
    
    //Play song
    [self playSong];
}

- (void) playSong
{
    //Reload songs when list empty
    if(songList == nil || [songList count] == 0)
        songList = [NSMutableArray arrayWithArray:[performingAlarm.songs array]];
    
    //When no songs selected for alarm or retry count exceeded play backup alarm sound
    if(songList == nil || [songList count] == 0 || songPlayTryCount == [performingAlarm.songs count])
    {
        [self playBackupAlarmSound];
        return;
    }
    
    songPlayTryCount++;

    //Find next song
    NSUInteger newSongIndex;
    if([performingAlarm.shuffle boolValue])
        newSongIndex = arc4random_uniform([songList count]);
    else
        newSongIndex = 0;
    
    AlarmSong * alarmSong = [songList objectAtIndex:newSongIndex];
    
    //Delete next song from list, so it will only be played once
    [songList removeObjectAtIndex:newSongIndex];
    
    [[SPSession sharedSession] trackForURL:[NSURL URLWithString:[alarmSong spotifyUrl]] callback:^(SPTrack *track)
    {
        if(track == nil)
        {
            performingAlarm = [Tools removeCorruptAlarmSong:alarmSong fromAlarm:performingAlarm];
            [self playSong];
            return;
        }
        
        [SPAsyncLoading waitUntilLoaded:track timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems)
         {
             if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPTrack class]])
             {
                 [self playBackupAlarmSound];
                 return;
             }
             
             [playBackManager playTrack:track callback:^(NSError *error)
              {
                  if(error != nil)
                  {
                      NSLog(@"PlaybackManager play error: %@", error);
                      [self playBackupAlarmSound];
                  }
              }];
         }];
        
    }];
}

- (void) playBackupAlarmSound
{
    //Return if already playing backup alarm sound
    if(self.audioPlayer != nil)
        return;
    
    //Play new sound
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:[Tools dateForAlarmBackupSound:[userDefaults integerForKey:@"BackupAlarmSound"]] fileTypeHint:AVFileTypeMPEGLayer3 error:&error];
    
    //Stop current spotify track
    [playBackManager stopTrack];
    
    //Check if init successful
    if(error != nil)
    {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not start backup sound!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
        NSLog(@"Could not start backup sound, error: %@", error);
        
        return;
    }
    
    //Set volume for progressive alarm volume
    if(songList == nil || [songList count] == 0)
        [self.audioPlayer setVolume:0];
    else
        [self.audioPlayer setVolume:[playBackManager volume]];
    
    [self.audioPlayer setNumberOfLoops:-1];
    [self.audioPlayer play];
}

#pragma mark State Update Methods
- (void) onTimer:(NSTimer *) timer
{
    [self updateClock];
    [self updateClockAlarm];
}

- (void) updateSpotifyConnectionState
{
    switch ([[SPSession sharedSession] connectionState])
    {
        case SP_CONNECTION_STATE_OFFLINE:
            self.spotifyConnectionState.text = @"Offline";
            break;            
        case SP_CONNECTION_STATE_DISCONNECTED:
            self.spotifyConnectionState.text = @"Disconnected";    
            break;            
        case SP_CONNECTION_STATE_LOGGED_IN:
            self.spotifyConnectionState.text = @"Online";
            break;            
        case SP_CONNECTION_STATE_LOGGED_OUT:
            self.spotifyConnectionState.text = @"Logged Out";
            break;            
        case SP_CONNECTION_STATE_UNDEFINED:
            self.spotifyConnectionState.text = @"Unknown";
            break;            
        default:
            self.spotifyConnectionState.text = @"Unknown";            
            break;
    }
}

-(void) updateClock
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateFormatter* timeFormatter = [[NSDateFormatter alloc] init];
    NSDateComponents * snoozeDateComponents = nil;
    if(snoozeDate != nil)
       snoozeDateComponents = [gregorian components:(NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:snoozeDate];
    
    
    //Retrieve time
    NSDate *time = [NSDate date];
    NSDateComponents * timeComponents = [gregorian components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSWeekdayCalendarUnit fromDate:time];
    
    //--------- Set time ---------/
    //Set Hours
    [timeFormatter setDateFormat:@"HH"];
    self.hour.text = [timeFormatter stringFromDate:time];
    
    //Set Minutes
    [timeFormatter setDateFormat:@"mm"];
    self.minutes.text = [timeFormatter stringFromDate:time];
    
    //Set colon and flip show colon
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"BlinkSecondsMarker"])
        self.colon.hidden = !showColon;
    else
        self.colon.hidden = YES;
    
    //Animate background glow on/off
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowBackgroundGlow"])
    {
        self.backgroundGlow.hidden = NO;
        
        [UIView animateWithDuration:1.0 animations:^(void) {
            if(showColon)
                self.backgroundGlow.alpha = 1.0f;
            else
                self.backgroundGlow.alpha = 0.5f;
        }];
    }
    else
        self.backgroundGlow.hidden = YES;
    
    
    //--------- Check alarm ---------/
    if(!isPerformingAlarm && timeComponents.weekday == nextAlarm.alarmDateComponents.weekday && timeComponents.hour == nextAlarm.alarmDateComponents.hour && timeComponents.minute == nextAlarm.alarmDateComponents.minute)
        [self performAlarm:[nextAlarm alarm]];
    else if(!isPerformingAlarm && snoozeDate != nil && timeComponents.weekday == snoozeDateComponents.weekday && timeComponents.hour == snoozeDateComponents.hour && timeComponents.minute == snoozeDateComponents.minute)
        [self performAlarm:performingAlarm];
    
    //--------- Set date ---------/
    [timeFormatter setDateFormat:@"dd-MM-yyyy"];
    NSInteger weekday = [[gregorian components:NSWeekdayCalendarUnit fromDate:time] weekday];
    self.lbDate.text = [NSString stringWithFormat:@"%@ %@", [Tools shortWeekDaySymbolForUnit:weekday], [timeFormatter stringFromDate:time]];
    
    //--------- Set next alarm ---------/
    //Determine next alarm every minute
    if([[gregorian components:NSSecondCalendarUnit fromDate:time] second] == 0)
        nextAlarm = [NextAlarm provide];
    
    //Check if snooze date is in future
    if(snoozeDate != nil && [[NSDate date] compare:snoozeDate] == NSOrderedDescending)
        snoozeDate = nil;
    
    self.miniAlarmImage.hidden = (nextAlarm == nil && snoozeDate == nil);
    self.lbNextAlarm.hidden = (nextAlarm == nil && snoozeDate == nil);
    
    if(snoozeDate != nil)
    {
        if(weekday == snoozeDateComponents.weekday)
            self.lbNextAlarm.text = [NSString stringWithFormat:@"%02d:%02d", snoozeDateComponents.hour, snoozeDateComponents.minute];
        else
            self.lbNextAlarm.text = [NSString stringWithFormat:@"%@ %02d:%02d", [Tools shortWeekDaySymbolForUnit:snoozeDateComponents.weekday], snoozeDateComponents.hour, snoozeDateComponents.minute];
    }
    else
    {
        if(weekday == nextAlarm.alarmDateComponents.weekday)
            self.lbNextAlarm.text = [NSString stringWithFormat:@"%02d:%02d", nextAlarm.alarmDateComponents.hour, nextAlarm.alarmDateComponents.minute];
        else
            self.lbNextAlarm.text = [NSString stringWithFormat:@"%@ %02d:%02d", [Tools shortWeekDaySymbolForUnit:nextAlarm.alarmDateComponents.weekday], nextAlarm.alarmDateComponents.hour, nextAlarm.alarmDateComponents.minute];
    }
    
    showColon ^= true;
}

- (void) updateClockAlarm
{
    //Only update when alarm is running
    if(!isPerformingAlarm)
        return;
        
    self.alarmBackground.hidden ^= YES;
    
    if(self.alarmBackground.hidden)
    {
        self.topBarAlarm.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
        self.bottomBarAlarm.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
    }
    else
    {
        self.topBarAlarm.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
        self.bottomBarAlarm.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    }
    
    //Increase volume until max
    float increaseVolume = 0.05;
    if(audioPlayer != nil && [audioPlayer volume] < 1)
        audioPlayer.volume += increaseVolume;
    else if(audioPlayer == nil && [playBackManager volume] < 1)
        playBackManager.volume += increaseVolume;
}
    
#pragma Alarm Handling Methods
- (IBAction) stopAlarm
{
    UIActionSheet * confirm = [[UIActionSheet alloc] initWithTitle:@"Do you really want to stop the alarm?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Yes" otherButtonTitles:@"No", nil];
    [confirm setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    [confirm showInView:self.view];
}

- (void) stopAlarmConfirmed
{
    isPerformingAlarm = NO;
    performingAlarm = nil;
    songList = nil;
    snoozeDate = nil;
    playBackManager.volume = 1;
    audioPlayer.volume = 1;
    songPlayTryCount = 0;
    [Tools setSystemVolume:self.systemVolume];
    [self enableTapGestures:YES];
    
    //Hide ClockAlarm view
    self.topBarAlarm.hidden = YES;
    self.bottomBarAlarm.hidden = YES;
    self.alarmBackground.hidden = YES;
    
    [playBackManager stopTrack];
    if(audioPlayer != nil)
    {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
    }
}

 - (IBAction) snoozeAlarm
 {
     isPerformingAlarm = NO;
     playBackManager.volume = 1;
     audioPlayer.volume = 1;
     songPlayTryCount = 0;
     [Tools setSystemVolume:self.systemVolume];
     [self enableTapGestures:YES];
     
     snoozeDate = [[NSDate date] dateByAddingTimeInterval:60*9];
     
     //Hide ClockAlarm view
     self.topBarAlarm.hidden = YES;
     self.bottomBarAlarm.hidden = YES;
     self.alarmBackground.hidden = YES;
     
     [playBackManager stopTrack];
     if(audioPlayer != nil)
     {
         [self.audioPlayer stop];
         self.audioPlayer = nil;
     }
 }

#pragma UIActionsheet delegate methods

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
        [self stopAlarmConfirmed];
}

#pragma SPSessionDelegate methods

- (void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error
{
    if(performingAlarm)
        [self playBackupAlarmSound];
}

- (void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error
{
    if(performingAlarm)
        [self playBackupAlarmSound];
}

-(UIViewController *)viewControllerToPresentLoginViewForSession:(SPSession *)aSession
{
    if(![userDefaults boolForKey:@"UseAlarmClockWithoutSpotify"])
        return [[LoginViewController alloc] init];
    else
        return nil;
}

#pragma mark - SPPlackbackManager delegate

-(void)playbackManagerWillStartPlayingAudio:(SPPlaybackManager *)aPlaybackManager
{
    songPlayTryCount = 0;
}
-(void)playbackManagerAudioProgress:(SPPlaybackManager *)aPlaybackManager progress:(double) progress { }
-(void)playbackManagerStoppedPlayingAudio:(SPPlaybackManager *)aPlaybackManager
{
    //If alarm still active play new song
    if(isPerformingAlarm && audioPlayer == nil)
        [self playSong];
}
-(void)playbackManagerDidLosePlayToken:(SPPlaybackManager *)aPlaybackManager
{
    if(performingAlarm)
        [self playBackupAlarmSound];
}

-(void)playbackManagerDidEncounterStreamingError:(SPPlaybackManager *)aPlaybackManager error:(NSError *) error
{
    if(performingAlarm)
    {
        if([error code] == SP_ERROR_NO_STREAM_AVAILABLE)
        {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode  = MBProgressHUDModeCustomView;
            hud.progress = 1.0f;
            hud.labelText = [NSString stringWithFormat:@"'%@' unavailable!", [aPlaybackManager.currentTrack name]];
            hud.detailsLabelText = @" Skipping to next track...";
            [hud hide:YES afterDelay:3.0f];
            
            [playBackManager stopTrack];//Stop track, so new track will be started
        }
        else
            [self playBackupAlarmSound];
    }
}


@end
