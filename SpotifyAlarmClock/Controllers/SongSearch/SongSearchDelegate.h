//
//  SongSearchDelegate.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 10-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPTrack;

@protocol SongSearchDelegate <NSObject>
    - (void)trackAdded:(SPTrack *)track;
    - (void)trackRemoved:(SPTrack *)track;
    - (bool)isTrackAdded:(SPTrack *)track;
@end
