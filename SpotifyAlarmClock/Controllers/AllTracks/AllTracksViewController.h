//
//  AllTracksViewController.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 04-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpotifyPlayer.h"
#import "SongSearchDelegate.h"

@interface AllTracksViewController : UITableViewController<SpotifyPlayerDelegate>
    @property (nonatomic, strong) NSString *searchText;
    @property(nonatomic, weak) id<SongSearchDelegate> songSearchDelegate;
@end
