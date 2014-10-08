//
//  CellConstructHelper.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 08-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "CellConstructHelper.h"
#import "CocoaLibSpotify.h"
#import "TrackCell.h"
#import "AlbumCell.h"
#import "ArtistCell.h"
#import "MaskHelper.h"
#import "ArtistBrowseCache.h"
#import "SpotifyPlayer.h"
#import "FFCircularProgressView.h"

@implementation CellConstructHelper

+ (TrackCell *)tableView:(UITableView*)tableView cellForTrack:(SPTrack *)track atIndexPath:(NSIndexPath *)indexPath musicProgressView:(FFCircularProgressView *)musicProgressView;
{
    TrackCell *cell = [tableView dequeueReusableCellWithIdentifier:@"trackCell" forIndexPath:indexPath];
    
    NSString *artistsText = @"";
    for(NSInteger i = 0; i < [track.artists count]; i++)
    {
        artistsText = [artistsText stringByAppendingString:[[track.artists objectAtIndex:i] name]];
        if(i < ([track.artists count] -1))
            artistsText = [artistsText stringByAppendingString:@" - "];
    }
    [cell.lbArtist setText:artistsText];
    [cell.lbTrack setText:[track name]];
    [MaskHelper addCircleMaskToView:[cell vwPlay]];
    
    for(UIView* subView in [cell.vwPlay subviews])
        [subView removeFromSuperview];
    
    if([[SpotifyPlayer sharedSpotifyPlayer] currentTrack] == track)
        [cell.vwPlay addSubview:musicProgressView];
    else
    {
        UIImageView* playImageView = [[UIImageView alloc] initWithFrame:[cell.vwPlay bounds]];
        [playImageView setImage:[UIImage imageNamed:@"Play"]];
        [cell.vwPlay addSubview:playImageView];
    }
    
    
    return cell;
}

+ (ArtistCell *)tableView:(UITableView*)tableView cellForArtist:(SPArtist *)artist atIndexPath:(NSIndexPath *)indexPath  artistBrowseCache:(ArtistBrowseCache *) artistBrowseCache;
{
    ArtistCell *cell = [tableView dequeueReusableCellWithIdentifier:@"artistCell" forIndexPath:indexPath];
    [cell.lbArtist setText:[artist name]];
    [cell.artistImage layer].cornerRadius = [cell.artistImage layer].frame.size.height /2;
    [cell.artistImage layer].masksToBounds = YES;
    [cell.artistImage layer].borderWidth = 0;
    
    SPArtistBrowse * artistBrowse = [artistBrowseCache artistBrowseForArtist:artist];
    
    if(artistBrowse.loaded && artistBrowse.firstPortrait.loaded)
        [cell.artistImage setImage:[artistBrowse.firstPortrait image]];
    else if(artistBrowse.loaded && artistBrowse.albums != nil && [artistBrowse.albums count] > 0 && ((SPAlbum *)[artistBrowse.albums firstObject]).cover.loaded)
        [cell.artistImage setImage:[((SPAlbum *)[artistBrowse.albums firstObject]).cover image]];
    else
        [cell.artistImage setImage:[UIImage imageNamed:@"Artist"]];
    
    return cell;
}

+ (AlbumCell *)tableView:(UITableView*)tableView cellForAlbum:(SPAlbum *)album atIndexPath:(NSIndexPath *)indexPath;
{
    AlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"albumCell" forIndexPath:indexPath];
    [cell.lbArtist setText:[album.artist name]];
    [cell.lbAlbum setText:[album name]];
    
    if([album.cover isLoaded])
        [cell.albumImage setImage:[album.cover image]];
    else
    {
        [cell.albumImage setImage:[UIImage imageNamed:@"Album"]];
        
        [album.cover startLoading];
        [SPAsyncLoading waitUntilLoaded:album.cover timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
         {
             if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPImage class]])
                 return;
             
             SPImage *cover = (SPImage*)[loadedItems firstObject];
             
             [cell.albumImage setImage:[cover image]];
         }];
        
    }
    
    [cell.albumImage sizeToFit];
    
    return cell;
}

@end
