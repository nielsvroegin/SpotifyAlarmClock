//
//  SongSearchViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 23-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "SongSearchViewController.h"
#import "CocoaLibSpotify.h"
#import "MBProgressHUD.h"
#import "ArtistCell.h"
#import "AlbumCell.h"
#import "TrackCell.h"
#import "SpotifyPlayer.h"
#import "FFCircularProgressView.h"

@interface SongSearchViewController ()
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) SPSearch *searchResult;
@property (nonatomic, strong) NSMutableArray *artistBrowseCollection;
@property (nonatomic, strong) NSMutableArray *albumBrowseCollection;
@property (nonatomic, strong) FFCircularProgressView *musicProgressView;

@property (atomic, assign) BOOL loading;
@property (nonatomic, assign) NSInteger artistSection;
@property (nonatomic, assign) NSInteger albumSection;
@property (nonatomic, assign) NSInteger trackSection;

- (void) performSearch;
- (TrackCell *)cellForTrackAtIndexPath:(NSIndexPath *)indexPath;
- (ArtistCell *)cellForArtistAtIndexPath:(NSIndexPath *)indexPath;
- (AlbumCell *)cellForAlbumAtIndexPath:(NSIndexPath *)indexPath;
- (SPArtistBrowse *) ArtistBrowseForArtist:(SPArtist *)artist;
- (void)addCircleMaskToView:(UIView *)view;

@end

@implementation SongSearchViewController
@synthesize searchBar;
@synthesize searchResult;
@synthesize artistSection, albumSection, trackSection;
@synthesize artistBrowseCollection;
@synthesize musicProgressView;

- (void)viewDidLoad {
    [[SpotifyPlayer sharedSpotifyPlayer] setDelegate:self];
    
    musicProgressView = [[FFCircularProgressView alloc] init];
    [musicProgressView setTintColor:[UIColor colorWithRed:(24 / 255.0) green:(109 / 255.0) blue:(39 / 255.0) alpha:1]];
    
    [searchBar becomeFirstResponder];

    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(SPArtistBrowse *) ArtistBrowseForArtist:(SPArtist *)artist
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
              NSInteger indexOfArtist = [self.searchResult.artists indexOfObject:artist];
              if(indexOfArtist != NSNotFound)
              {
                  ArtistCell * cell = (ArtistCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.searchResult.artists indexOfObject:artist] inSection:artistSection]];
                  [cell.artistImage setImage:[portrait image]];
              }
          }];
     }];
    
    return artistBrowse;
}

-(void) performSearch
{
    //Ignore search change when still loading
    if(self.loading)
        return;
    
    //Set loading and clean table
    self.loading = true;
    
    //Perform search
    SPSearch *search = [[SPSearch alloc] initWithSearchQuery:[self.searchBar text] pageSize:4 inSession:[SPSession sharedSession] type:SP_SEARCH_SUGGEST];
    [SPAsyncLoading waitUntilLoaded:search timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
     {
         //Disable loading HUD
         [MBProgressHUD hideAllHUDsForView:self.tableView animated:YES];
         
         //Check if search wasn't timed out
         if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPSearch class]])
         {
             [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify Alarm Clock wasn't able to perform the search. Is your internet connection still active?" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
             NSLog(@"Search request timedout");
             
             return;
         }
         
         //Check if search text still the same, otherwise redo search
         SPSearch *search = (SPSearch*)[loadedItems firstObject];
         if(![search.searchQuery isEqualToString:[self.searchBar text]])
         {
             self.loading = false;
             if([[self.searchBar text] length] > 0)
                 [self performSearch];
             
             return;
         }
         
         //Search successful, add to search result and reload table
         self.artistBrowseCollection = [[NSMutableArray alloc] init];
         self.searchResult = search;
         [self.tableView reloadData];
         
         self.loading = false;
     }];
    
}

- (void)addCircleMaskToView:(UIView *)view {
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = view.bounds;
    maskLayer.path = [UIBezierPath bezierPathWithOvalInRect:view.bounds].CGPath;
    maskLayer.fillColor = [UIColor whiteColor].CGColor;
    view.layer.mask = maskLayer;
}

#pragma mark - Searchbar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
    
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    //Cancel any previous request if still waiting
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performSearch) object:nil];
    
    //Clear table
    self.artistBrowseCollection = [[NSMutableArray alloc] init];
    self.searchResult = nil;
    [self.tableView reloadData];
    
    //No need to search if searchtext is empty
    if([self.searchBar.text length] == 0)
    {
        [MBProgressHUD hideAllHUDsForView:self.tableView animated:YES];
        return;
    }
    
    //Enable loading HUD
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    hud.labelText = @"Loading";
    
    //Perform the search
    [self performSelector:@selector(performSearch) withObject:nil afterDelay:0.5];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = 0;
    
    if([[self.searchResult tracks] count] > 0)
    {
        self.trackSection = sections;
        sections++;
    }
    else
        self.trackSection = -1;
    
    if([[self.searchResult artists] count] > 0)
    {
        self.artistSection = sections;
        sections++;
    }
    else
        self.artistSection = -1;
    
    if([[self.searchResult albums] count] > 0)
    {
        self.albumSection = sections;
        sections++;
    }
    else
        self.albumSection = -1;
    
    return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(self.trackSection == section)
        return @"Tracks";
    else if(self.artistSection == section)
        return @"Artists";
    else if(self.albumSection == section)
        return @"Albums";
    else
        return @"";
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if(self.trackSection == section)
        return [self.searchResult.tracks count] + 1;
    else if(self.artistSection == section)
        return [self.searchResult.artists count] + 1;
    else if(self.albumSection == section)
        return [self.searchResult.albums count] + 1;
    else
        return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if(self.trackSection == indexPath.section)
    {
        if([indexPath row] == [self.searchResult.tracks count])
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"allCell" forIndexPath:indexPath];
            [cell.textLabel setText:@"View all tracks"];
        }
        else
            cell = [self cellForTrackAtIndexPath:indexPath];
    }
    else if(self.artistSection == indexPath.section)
    {
        if([indexPath row] == [self.searchResult.artists count])
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"allCell" forIndexPath:indexPath];
            [cell.textLabel setText:@"View all artists"];
        }
        else
            cell = [self cellForArtistAtIndexPath:indexPath];
    }
    else if(self.albumSection == indexPath.section)
    {
        if([indexPath row] == [self.searchResult.albums count])
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"allCell" forIndexPath:indexPath];
            [cell.textLabel setText:@"View all albums"];
        }
        else
            cell = [self cellForAlbumAtIndexPath:indexPath];
    }
    
    return cell;
}

- (TrackCell *)cellForTrackAtIndexPath:(NSIndexPath *)indexPath
{
    SPTrack *track = [self.searchResult.tracks objectAtIndex:[indexPath row]];
    TrackCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"trackCell" forIndexPath:indexPath];

    NSString *artistsText = @"";
    for(NSInteger i = 0; i < [track.artists count]; i++)
    {
        artistsText = [artistsText stringByAppendingString:[[track.artists objectAtIndex:i] name]];
        if(i < ([track.artists count] -1))
            artistsText = [artistsText stringByAppendingString:@" - "];
    }
    [cell.lbArtist setText:artistsText];
    [cell.lbTrack setText:[track name]];
    [self addCircleMaskToView:[cell vwPlay]];

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

- (ArtistCell *)cellForArtistAtIndexPath:(NSIndexPath *)indexPath
{
    SPArtist *artist = [self.searchResult.artists objectAtIndex:[indexPath row]];
    
    ArtistCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"artistCell" forIndexPath:indexPath];
    [cell.lbArtist setText:[artist name]];
    [cell.artistImage layer].cornerRadius = [cell.artistImage layer].frame.size.height /2;
    [cell.artistImage layer].masksToBounds = YES;
    [cell.artistImage layer].borderWidth = 0;
    
    SPArtistBrowse * artistBrowse = [self ArtistBrowseForArtist:artist];
    
    if(artistBrowse.loaded && artistBrowse.firstPortrait.loaded)
        [cell.artistImage setImage:[artistBrowse.firstPortrait image]];
    else if(artistBrowse.loaded && artistBrowse.albums != nil && [artistBrowse.albums count] > 0 && ((SPAlbum *)[artistBrowse.albums firstObject]).cover.loaded)
        [cell.artistImage setImage:[((SPAlbum *)[artistBrowse.albums firstObject]).cover image]];
    else
        [cell.artistImage setImage:[UIImage imageNamed:@"Artist"]];
    
    return cell;
}

- (AlbumCell *)cellForAlbumAtIndexPath:(NSIndexPath *)indexPath
{
    SPAlbum *album = [self.searchResult.albums objectAtIndex:[indexPath row]];
    
    AlbumCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"albumCell" forIndexPath:indexPath];
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

#pragma mark - UITableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == artistSection)
    {
        if([indexPath row] == [self.searchResult.artists count])
            return 40;
        else
            return 75;
    }
    else if(indexPath.section == albumSection)
    {
        if([indexPath row] == [self.searchResult.albums count])
            return 40;
        else
            return 75;
    }
    else if(indexPath.section == trackSection)
    {
        if([indexPath row] == [self.searchResult.tracks count])
            return 40;
        else
            return 55;
    }

    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.searchBar resignFirstResponder];
    
    if(indexPath.section == trackSection)
    {
        SPTrack *track = [self.searchResult.tracks objectAtIndex:[indexPath row]];
        if([[SpotifyPlayer sharedSpotifyPlayer] currentTrack] == track)
            [[SpotifyPlayer sharedSpotifyPlayer] stopTrack];
        else
            [[SpotifyPlayer sharedSpotifyPlayer] playTrack:track];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([self.searchBar isFirstResponder])
        [self.searchBar resignFirstResponder];
    
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - Spotify Player delegate

- (void)track:(SPTrack *)track progess:(double) progress
{
    if(progress >= 1.0) progress = 0.999;
    [musicProgressView setProgress:progress];
}

- (void)trackStartedPlaying:(SPTrack *)track
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.searchResult.tracks indexOfObject:track] inSection:trackSection]];
    [musicProgressView setFrame:[cell.vwPlay bounds]];
    [musicProgressView setProgress:0.01];
    
    [UIView transitionWithView:cell.vwPlay
                      duration:1.0
                       options:UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionShowHideTransitionViews
                    animations:^{
                        for(UIView* subView in [cell.vwPlay subviews])
                            [subView removeFromSuperview];

                        [cell.vwPlay addSubview:musicProgressView];

                    } completion:nil];
    
}

- (void)trackStoppedPlaying:(SPTrack *)track
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.searchResult.tracks indexOfObject:track] inSection:trackSection]];
    UIImageView* playImageView = [[UIImageView alloc] initWithFrame:[cell.vwPlay bounds]];
    [playImageView setImage:[UIImage imageNamed:@"Play"]];
    
    [UIView transitionWithView:cell.vwPlay
                      duration:1.0
                       options:UIViewAnimationOptionTransitionFlipFromRight | UIViewAnimationOptionShowHideTransitionViews
                    animations:^{
                        for(UIView* subView in [cell.vwPlay subviews])
                            [subView removeFromSuperview];
                        
                        [cell.vwPlay addSubview:playImageView];
                        
                    } completion:nil];
    
    [self.musicProgressView setProgress:0.01];
}


@end
