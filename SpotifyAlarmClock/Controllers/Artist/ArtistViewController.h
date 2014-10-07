//
//  ArtistViewController.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 04-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPArtist;
@class SPArtistBrowse;

@interface ArtistViewController : UITableViewController
    @property (nonatomic, strong) SPArtistBrowse *artistBrowse;

@end
