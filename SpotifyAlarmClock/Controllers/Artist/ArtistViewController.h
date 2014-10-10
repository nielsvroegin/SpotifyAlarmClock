//
//  ArtistViewController.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 04-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpotifyPlayer.h"

@class SPArtistBrowse;

@interface ArtistViewController : UITableViewController<SpotifyPlayerDelegate>
    @property (nonatomic, strong) SPArtistBrowse *artistBrowse;

@end
