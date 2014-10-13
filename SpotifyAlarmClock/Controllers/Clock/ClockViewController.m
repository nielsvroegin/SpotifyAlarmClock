//
//  ClockViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 17-09-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ClockViewController.h"
//#import "HelperFunctions.h"



@implementation ClockViewController
@synthesize spotifyConnectionState;
@synthesize hour;
@synthesize colon;
@synthesize minutes;
@synthesize backgroundGlow;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        loginChecked = NO;
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
    
    //Keep app awake
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    //Time digits glow
    hour.layer.shadowColor = [[UIColor yellowColor] CGColor];
    hour.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    hour.layer.shadowRadius = 4.0;
    hour.layer.shadowOpacity = 0.3;
    hour.layer.masksToBounds = NO;
    
    colon.layer.shadowColor = [[UIColor yellowColor] CGColor];
    colon.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    colon.layer.shadowRadius = 4.0;
    colon.layer.shadowOpacity = 0.3;
    colon.layer.masksToBounds = NO;
    
    minutes.layer.shadowColor = [[UIColor yellowColor] CGColor];
    minutes.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    minutes.layer.shadowRadius = 4.0;
    minutes.layer.shadowOpacity = 0.3;
    minutes.layer.masksToBounds = NO;
    
    
    [self updateClock];
    
    NSError *error = nil;
    [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]
                                               userAgent:@"nl.startsmart.SpotifyAlarmClock"
                                           loadingPolicy:SPAsyncLoadingManual
                                                   error:&error];
    
    [SPSession sharedSession].delegate = self;
    [[SPSession sharedSession] attemptLoginWithUserName:@"nielsvroegin" password:@"51casioc"];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(onTimer:)
                                   userInfo:nil
                                    repeats:YES];
}

// for ios 7
- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    
    //Set Hours
    [timeFormatter setDateFormat:@"HH"];
    self.hour.text = [timeFormatter stringFromDate:time];
    
    //Set Minutes
    [timeFormatter setDateFormat:@"mm"];
    self.minutes.text = [timeFormatter stringFromDate:time];
    
    //Animate background glow on/off
    [UIView animateWithDuration:1.0 animations:^(void) {
        if(showColon)
        {
            self.backgroundGlow.alpha = 1.0f;
        }
        else
        {
            self.backgroundGlow.alpha = 0.5f;
        }
        
    }];

    
    //Set colon and flip show colon
    self.colon.hidden = !showColon;
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
