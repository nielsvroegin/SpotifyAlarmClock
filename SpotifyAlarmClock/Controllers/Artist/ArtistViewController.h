//
//  ArtistViewController.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 04-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPArtist;

@interface ArtistViewController : UITableViewController
    @property (nonatomic, strong) SPArtist *artist;

@end
