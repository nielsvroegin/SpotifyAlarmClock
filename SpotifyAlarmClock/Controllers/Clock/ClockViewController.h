//
//  ClockViewController.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 17-09-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "LoginViewController.h"
//#import "SettingsViewController.h"
#import "CocoaLibSpotify.h"
#import "appkey.h"
#import "SpotifyPlayer.h"
#import "BackgroundGlow.h"

@interface ClockViewController : UIViewController <SPSessionDelegate>
{
    @private
    bool showColon;    
    bool loginChecked;
}


@property (nonatomic, retain) IBOutlet UILabel *spotifyConnectionState;
@property (nonatomic, retain) IBOutlet UILabel *hour;
@property (nonatomic, retain) IBOutlet UILabel *colon;
@property (nonatomic, retain) IBOutlet UILabel *minutes;
@property (weak, nonatomic) IBOutlet BackgroundGlow *backgroundGlow;

- (void) updateSpotifyConnectionState;
- (void) updateClock;
- (IBAction)backgroundTap;
- (IBAction)unwindToClock:(UIStoryboardSegue *)unwindSegue;

@end
