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
#import "Tools.h"

@interface ClockViewController ()

@property (nonatomic, assign) bool showColon;
@property (nonatomic, assign) bool loginChecked;
@property (nonatomic, strong) NSDateComponents * nextAlarm;
@property (weak, nonatomic) IBOutlet UILabel *spotifyConnectionState;
@property (weak, nonatomic) IBOutlet UILabel *hour;
@property (weak, nonatomic) IBOutlet UILabel *colon;
@property (weak, nonatomic) IBOutlet UILabel *minutes;
@property (weak, nonatomic) IBOutlet BackgroundGlow *backgroundGlow;
@property (weak, nonatomic) IBOutlet UILabel *lbDate;
@property (weak, nonatomic) IBOutlet UILabel *lbNextAlarm;
@property (weak, nonatomic) IBOutlet UIImageView *miniAlarmImage;

- (void) updateSpotifyConnectionState;
- (void) updateClock;
- (IBAction)backgroundTap;
- (IBAction)unwindToClock:(UIStoryboardSegue *)unwindSegue;
- (void) applyGlow:(UILabel*)label;
- (void)applyBackgroundTapRecursive:(UIView *)vw;

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
@synthesize nextAlarm;
@synthesize miniAlarmImage;


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
    
    [[SPSession sharedSession] setDelegate:self];
    [[SPSession sharedSession] attemptLoginWithUserName:@"nielsvroegin" password:@"51casioc"];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Determine next alarm
    nextAlarm = [NextAlarm provide];
    
    //Update clock
    [self updateClock];
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
         [self applyBackgroundTapRecursive:subView];
     }
}

- (void) timeChangedSignificant
{
    self.nextAlarm = [NextAlarm provide];
    [self updateClock];
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
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
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
    [timeFormatter setDateFormat:@"dd-MM-yyyy"];
    NSInteger weekday = [[gregorian components:NSWeekdayCalendarUnit fromDate:time] weekday];
    self.lbDate.text = [NSString stringWithFormat:@"%@ %@", [Tools shortWeekDaySymbolForUnit:weekday], [timeFormatter stringFromDate:time]];
    
    //--------- Set next alarm ---------/
    //Determine next alarm every minute
    if([[gregorian components:NSSecondCalendarUnit fromDate:time] second] == 0)
        nextAlarm = [NextAlarm provide];
    
    self.miniAlarmImage.hidden = (nextAlarm == nil);
    self.lbNextAlarm.hidden = (nextAlarm == nil);
    self.lbNextAlarm.text = [NSString stringWithFormat:@"%@ %02d:%02d", [Tools shortWeekDaySymbolForUnit:nextAlarm.weekday], nextAlarm.hour, nextAlarm.minute];
    
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
