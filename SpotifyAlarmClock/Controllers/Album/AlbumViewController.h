//
//  AlbumViewController.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 10-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpotifyPlayer.h"
#import "SongSearchDelegate.h"

@class SPAlbum;

@interface AlbumViewController : UITableViewController<SpotifyPlayerDelegate>
    @property (nonatomic, strong) SPAlbum *album;
    @property(nonatomic, weak) id<SongSearchDelegate> songSearchDelegate;
@end
