//
//  SongSearchViewController.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 23-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPPlaybackManager.h"
#import "ArtistBrowseCache.h"
#import "SongSearchDelegate.h"

@interface SongSearchViewController : UITableViewController<UISearchBarDelegate, SPPlaybackManagerDelegate, ArtistBrowseCacheDelegate>

@property(nonatomic, weak) id<SongSearchDelegate> songSearchDelegate;

@end
