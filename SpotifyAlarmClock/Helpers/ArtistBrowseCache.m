//
//  ArtistBrowseCache.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 04-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "ArtistBrowseCache.h"
#import "CocoaLibSpotify.h"
#import "ArtistCell.h"

@interface ArtistBrowseCache ()
    @property (nonatomic, strong) NSMutableArray *artistBrowseCollection;
@end

@implementation ArtistBrowseCache
@synthesize artistBrowseCollection;

- (id)init {
    self = [super init];
    if (self) {
        artistBrowseCollection = [[NSMutableArray alloc] init];
    }
    return self;
}


-(SPArtistBrowse *) ArtistBrowseForArtist:(SPArtist *)artist searchResult:(SPSearch *)searchResult tableView:(UITableView *)tableView artistSection:(NSInteger)artistSection
{
    SPArtistBrowse * artistBrowse = nil;
    
    //Try to find artist browse in collection
    for(SPArtistBrowse* ab in self.artistBrowseCollection)
        if(ab.artist == artist)
            artistBrowse = ab;
    
    if(artistBrowse != nil)
        return artistBrowse;
    
    //Not found so create
    artistBrowse = [[SPArtistBrowse alloc] initWithArtist:artist inSession:[SPSession sharedSession] type:SP_ARTISTBROWSE_NO_TRACKS];
    [self.artistBrowseCollection addObject:artistBrowse];
    [SPAsyncLoading waitUntilLoaded:artistBrowse timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
     {
         if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPArtistBrowse class]])
             return;
         
         SPArtistBrowse *artistBrowse = (SPArtistBrowse*)[loadedItems firstObject];
         
         SPImage* artistImage = nil;
         if([artistBrowse firstPortrait] != nil)
             artistImage = [artistBrowse firstPortrait];
         else if(artistBrowse.albums != nil && [artistBrowse.albums count] > 0 && ((SPAlbum *)[artistBrowse.albums firstObject]).cover != nil)
             artistImage = ((SPAlbum *)[artistBrowse.albums firstObject]).cover;
         else
             return;
         
         [artistImage startLoading];
         [SPAsyncLoading waitUntilLoaded:artistImage timeout:10.0 then:^(NSArray *loadedPortraitItems, NSArray *notLoadedPortraitItems)
          {
              if(loadedPortraitItems == nil || [loadedPortraitItems count] != 1 || ![[loadedPortraitItems firstObject] isKindOfClass:[SPImage class]])
                  return;
              
              SPImage *portrait = (SPImage*)[loadedPortraitItems firstObject];
              NSInteger indexOfArtist = [searchResult.artists indexOfObject:artist];
              if(indexOfArtist != NSNotFound)
              {
                  ArtistCell * cell = (ArtistCell*)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[searchResult.artists indexOfObject:artist] inSection:artistSection]];
                  [cell.artistImage setImage:[portrait image]];
              }
          }];
     }];
    
    return artistBrowse;
}

-(void) clear
{
    [artistBrowseCollection removeAllObjects];
}

@end
