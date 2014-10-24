//
//  ArtistViewController.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 04-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPPlaybackManager.h"
#import "SongSearchDelegate.h"

@class SPArtistBrowse;

@interface ArtistViewController : UITableViewController<SPPlaybackManagerDelegate>
    @property (nonatomic, strong) SPArtistBrowse *artistBrowse;
    @property(nonatomic, weak) id<SongSearchDelegate> songSearchDelegate;
@end
