//
//  ClockViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 17-09-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ClockViewController.h"
#import "CocoaLibSpotify.h"
#import "appkey.h"
#import "BackgroundGlow.h"
#import "NextAlarm.h"

@interface ClockViewController ()

@property (nonatomic, assign) bool showColon;
@property (nonatomic, assign) bool loginChecked;
@property (weak, nonatomic) IBOutlet UILabel *spotifyConnectionState;
@property (weak, nonatomic) IBOutlet UILabel *hour;
@property (weak, nonatomic) IBOutlet UILabel *colon;
@property (weak, nonatomic) IBOutlet UILabel *minutes;
@property (weak, nonatomic) IBOutlet BackgroundGlow *backgroundGlow;
@property (weak, nonatomic) IBOutlet UILabel *lbDate;

- (void) updateSpotifyConnectionState;
- (void) updateClock;
- (IBAction)backgroundTap;
- (IBAction)unwindToClock:(UIStoryboardSegue *)unwindSegue;
- (void) applyGlow:(UILabel*)label;

@end

@implementation ClockViewController
@synthesize spotifyConnectionState;
@synthesize hour;
@synthesize colon;
@synthesize minutes;
@synthesize backgroundGlow;
@synthesize showColon;
@synthesize loginChecked;
@synthesize lbDate;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (IBAction)backgroundTap
{
    [self performSegueWithIdentifier:@"settingsSegue" sender:nil];
}

- (IBAction)unwindToClock:(UIStoryboardSegue *)unwindSegue { }

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //loginChecked = NO;
    
    //Keep app awake
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    //Time digits glow
    [self applyGlow:hour];
    [self applyGlow:colon];
    [self applyGlow:minutes];
    
    //Update clock
    [self updateClock];
    
    //Determine next alarm
    [NextAlarm provide];
    
    //Set timer to update clock
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    
    //Perform login on spotify
    NSError *error = nil;
    [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
                                               userAgent:@"nl.startsmart.SpotifyAlarmClock"
                                           loadingPolicy:SPAsyncLoadingManual
                                                   error:&error];
    
    [[SPSession sharedSession] setDelegate:self];
    [[SPSession sharedSession] attemptLoginWithUserName:@"nielsvroegin" password:@"51casioc"];
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

#pragma mark State Update Methods
- (void) onTimer:(NSTimer *) timer
{
    [self updateClock];
    [self updateSpotifyConnectionState];
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
    NSDateFormatter* timeFormatter = [[NSDateFormatter alloc] init];
    
    //Retrieve time
    NSDate *time = [NSDate date];
    
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
    
    //--------- Set date ---------/
    [timeFormatter setDateFormat:@"EE dd-MM-yyyy"];
    self.lbDate.text = [timeFormatter stringFromDate:time];
    
    showColon ^= true;
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


@end
