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

@protocol ArtistBrowseCacheDelegate <NSObject>

@optional
- (void)artistBrowseLoaded:(SPArtistBrowse *) artistBrowse;
- (void)artistPortraitLoaded:(UIImage *) artistPortrait artist:(SPArtist*)artist;

@end

@interface ArtistBrowseCache : NSObject

@property (nonatomic, weak) id<ArtistBrowseCacheDelegate> delegate;

-(SPArtistBrowse *) artistBrowseForArtist:(SPArtist *)artist;
-(void) clear;

@end
