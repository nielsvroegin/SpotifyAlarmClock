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


- (IBAction)playMusic
{
    
    
    [[SPSession sharedSession] trackForURL:[NSURL URLWithString:@"http://open.spotify.com/track/64eMQ7f31JSd8b9H6HUvvN"] callback:^(SPTrack *track){
        if (track != nil) {
            [SPAsyncLoading waitUntilLoaded:track timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *tracks, NSArray *notLoadedTracks) {
                [[SpotifyPlayer sharedSpotifyPlayer] playTrack:(SPTrack *)[tracks firstObject]];
            }];
        }
    }];
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
    
    //Set colon and flip show colon
    self.colon.hidden = showColon;
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
