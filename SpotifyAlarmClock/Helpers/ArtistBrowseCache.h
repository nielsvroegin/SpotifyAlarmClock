//
//  ArtistBrowseCache.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 04-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPArtistBrowse;
@class SPArtist;
@class SPSearch;

@interface ArtistBrowseCache : NSObject

-(SPArtistBrowse *) ArtistBrowseForArtist:(SPArtist *)artist searchResult:(SPSearch *)searchResult tableView:(UITableView *)tableView artistSection:(NSInteger)artistSection;
-(void) clear;

@end
