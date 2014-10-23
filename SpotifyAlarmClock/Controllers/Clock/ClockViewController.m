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
#import "CocoaLibSpotify.h"
#import "appkey.h"
#import "BackgroundGlow.h"
#import "NextAlarm.h"
#import "Tools.h"

@interface ClockViewController ()

@property (nonatomic, assign) bool showColon;
@property (nonatomic, assign) bool loginChecked;
@property (nonatomic, assign) bool isPerformingAlarm;
@property (nonatomic, assign) Alarm * performingAlarm;
@property (nonatomic, strong) NextAlarm * nextAlarm;
@property (nonatomic, strong) NSMutableArray * songList;
@property (nonatomic, strong) NSDate * snoozeDate;
@property (nonatomic, strong) SPPlaybackManager * playBackManager;

@property (weak, nonatomic) IBOutlet UILabel *spotifyConnectionState;
@property (weak, nonatomic) IBOutlet UILabel *hour;
@property (weak, nonatomic) IBOutlet UILabel *colon;
@property (weak, nonatomic) IBOutlet UILabel *minutes;
@property (weak, nonatomic) IBOutlet BackgroundGlow *backgroundGlow;
@property (weak, nonatomic) IBOutlet UILabel *lbDate;
@property (weak, nonatomic) IBOutlet UILabel *lbNextAlarm;
@property (weak, nonatomic) IBOutlet UIImageView *miniAlarmImage;

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
- (IBAction) performAlarm;
- (void) performAlarm:(Alarm *)alarm;
- (IBAction) stopAlarm;
- (IBAction) snoozeAlarm;
- (void) playSong;


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
    
    //loginChecked = NO;
    
    //Receive notification for significant time change/Locale change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timeChangedSignificant) name:UIApplicationSignificantTimeChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timeChangedSignificant) name:NSCurrentLocaleDidChangeNotification object:nil];
        
    //Register all views for background tap
    [self applyBackgroundTapRecursive:self.view];
    
    //Time digits glow
    [self applyGlow:hour];
    [self applyGlow:colon];
    [self applyGlow:minutes];
    
    //Set timer to update clock
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    
    //Perform login on spotify
    NSError *error = nil;
    [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
                                               userAgent:@"nl.startsmart.SpotifyAlarmClock"
                                           loadingPolicy:SPAsyncLoadingManual
                                                   error:&error];
    
    [[SPSession sharedSession] attemptLoginWithUserName:@"nielsvroegin" password:@"51casioc"];
    
    //Init playbackmanager
    playBackManager = [[SPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Set delegates
    [[SPSession sharedSession] setDelegate:self];
    [playBackManager setDelegate:self];
    
    //Determine next alarm
    nextAlarm = [NextAlarm provide];
    
    //Update clock
    [self updateClock];
}

- (void) viewDidAppear:(BOOL)animated
{
    //Keep app awake
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
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
    
     vw.userInteractionEnabled = YES;
     [vw addGestureRecognizer:tapGesture];
     for(UIView* subView in [vw subviews])
     {
         if([subView class] != [UIButton class])
             [self applyBackgroundTapRecursive:subView];
     }
}

- (void) timeChangedSignificant
{
    self.nextAlarm = [NextAlarm provide];
    [self updateClock];
}


- (IBAction) performAlarm
{
    [self performAlarm:nextAlarm.alarm];
}

- (void) performAlarm:(Alarm *)alarm
{
    isPerformingAlarm = true;
    performingAlarm = alarm;
    snoozeDate = nil;
    
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
    
    //Play song
    [self playSong];
}

- (void) playSong
{
    //Reload songs when list empty
    if(songList == nil || [songList count] == 0)
        songList = [NSMutableArray arrayWithArray:[performingAlarm.songs array]];

    //Find next song
    NSUInteger newSongIndex;
    if([performingAlarm.shuffle boolValue])
        newSongIndex = arc4random() % [songList count];
    else
        newSongIndex = 0;
    
    AlarmSong * alarmSong = [songList objectAtIndex:newSongIndex];
    
    //Delete next song from list, so it will only be played once
    [songList removeObjectAtIndex:newSongIndex];
    
    [[SPSession sharedSession] trackForURL:[NSURL URLWithString:[alarmSong spotifyUrl]] callback:^(SPTrack *track){
        //[[SpotifyPlayer sharedSpotifyPlayer] playTrack:track];
        [playBackManager playTrack:track callback:^(NSError *error)
        {
            NSLog(@"PlaybackManager play error: %@", error);
        }];
    }];
}

#pragma mark State Update Methods
- (void) onTimer:(NSTimer *) timer
{
    [self updateClock];
    [self updateSpotifyConnectionState];
    [self updateClockAlarm];
}

- (void) updateSpotifyConnectionState
{
    switch ([[SPSession sharedSession] connectionState])
    {
        case SP_CONNECTION_STATE_OFFLINE:
            self.spotifyConnectionState.text = @"Connected";
            break;            
        case SP_CONNECTION_STATE_DISCONNECTED:
            self.spotifyConnectionState.text = @"Disconnected";    
            break;            
        case SP_CONNECTION_STATE_LOGGED_IN:
            self.spotifyConnectionState.text = @"Online";
            break;            
        case SP_CONNECTION_STATE_LOGGED_OUT:
            self.spotifyConnectionState.text = @"Logged off";
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
    NSDateComponents * snoozeDateComponents = [gregorian components:(NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:snoozeDate];
    
    
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
    self.colon.hidden = !showColon;
    
    //Animate background glow on/off
    [UIView animateWithDuration:1.0 animations:^(void) {
        if(showColon)
            self.backgroundGlow.alpha = 1.0f;
        else
            self.backgroundGlow.alpha = 0.5f;
    }];
    
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
}
    
#pragma Alarm Handling Methods
 - (IBAction) stopAlarm
 {
     isPerformingAlarm = NO;
     performingAlarm = nil;
     songList = nil;
     snoozeDate = nil;
     
     //Hide ClockAlarm view
     self.topBarAlarm.hidden = YES;
     self.bottomBarAlarm.hidden = YES;
     self.alarmBackground.hidden = YES;
     
     [[SpotifyPlayer sharedSpotifyPlayer] stopTrack];
 }

 - (IBAction) snoozeAlarm
 {
     isPerformingAlarm = NO;
     
     snoozeDate = [[NSDate date] dateByAddingTimeInterval:60*9];
     
     //Hide ClockAlarm view
     self.topBarAlarm.hidden = YES;
     self.bottomBarAlarm.hidden = YES;
     self.alarmBackground.hidden = YES;
     
     [[SpotifyPlayer sharedSpotifyPlayer] stopTrack];
 }

#pragma SPSessionDelegate methods

- (void)sessionDidLoginSuccessfully:(SPSession *)aSession
{
    [self updateSpotifyConnectionState];
}

- (void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error
{
//    [self showLoginScreen];
}

- (void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error
{
    //Show error
    //[HelperFunctions notifySpotifyError:error withTitle:@"Network error"];
}

#pragma mark - SPPlackbackManager delegate

-(void)playbackManagerWillStartPlayingAudio:(SPPlaybackManager *)aPlaybackManager
{
    
}
-(void)playbackManagerStoppedPlayingAudio:(SPPlaybackManager *)aPlaybackManager
{
    //If alarm still active play new song
    if(isPerformingAlarm)
        [self playSong];
}
-(void)playbackManagerDidLosePlayToken:(SPPlaybackManager *)aPlaybackManager
{
}
-(void)playbackManagerAudioProgress:(SPPlaybackManager *)aPlaybackManager progress:(NSTimeInterval) progress
{
    
}
-(void)playbackManagerDidEncounterStreamingError:(SPPlaybackManager *)aPlaybackManager error:(NSError *) error
{
    
}


@end
