//
//  SongsViewController.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 23-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SongSearchDelegate.h"
#import "SongsDelegate.h"
#import "SPPlaybackManager.h"

@class Alarm;

@interface SongsViewController : UITableViewController<SongSearchDelegate, SPPlaybackManagerDelegate>

@property (nonatomic, weak) id<SongsDelegate> delegate;
@property (nonatomic, strong) NSOrderedSet *alarmSongs;

- (IBAction)unwindToSongs:(UIStoryboardSegue *)unwindSegue;

@end
