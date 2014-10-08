//
//  CellConstructHelper.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 08-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TrackCell;
@class ArtistCell;
@class AlbumCell;
@class SPTrack;
@class SPArtist;
@class SPAlbum;
@class FFCircularProgressView;
@class ArtistBrowseCache;


@interface CellConstructHelper : NSObject

+ (TrackCell *)tableView:(UITableView*)tableView cellForTrack:(SPTrack *)track atIndexPath:(NSIndexPath *)indexPath;
+ (ArtistCell *)tableView:(UITableView*)tableView cellForArtist:(SPArtist *)artist atIndexPath:(NSIndexPath *)indexPath artistBrowseCache:(ArtistBrowseCache *) artistBrowseCache;
+ (AlbumCell *)tableView:(UITableView*)tableView cellForAlbum:(SPAlbum *)album atIndexPath:(NSIndexPath *)indexPath;

@end
