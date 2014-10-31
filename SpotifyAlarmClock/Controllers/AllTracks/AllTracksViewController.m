//
//  AllTracksViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 04-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "AllTracksViewController.h"
#import "CocoaLibSpotify.h"
#import "TrackCell.h"
#import "MBProgressHUD.h"
#import "LoadMoreCell.h"
#import "CellConstructHelper.h"
#import "Tools.h"

@interface AllTracksViewController ()

@property (nonatomic, strong) SPSearch *searchResult;

- (void)loadMoreTracks;
- (void) addSongButtonClicked:(id)sender;

@end

@implementation AllTracksViewController
@synthesize searchText;
@synthesize songSearchDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Register cells
    [self.tableView registerNib:[UINib nibWithNibName:@"TrackCell" bundle:nil] forCellReuseIdentifier:@"trackCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"LoadMoreCell" bundle:nil] forCellReuseIdentifier:@"loadingMoreCells"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SPPlaybackManager * playBackManager = [SPPlaybackManager sharedPlaybackManager];
    [playBackManager setDelegate:self];
    
    //Empty remaining search results
    self.searchResult = nil;
    [self.tableView reloadData];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    hud.labelText = @"Loading";
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    SPSearch *search = [[SPSearch alloc] initWithSearchQuery:[self searchText] pageSize:30 inSession:[SPSession sharedSession] type:SP_SEARCH_STANDARD];
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
         
         //Set search result and reload table
         self.searchResult = (SPSearch*)[loadedItems firstObject];
         [self.tableView reloadData];
     }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[SPPlaybackManager sharedPlaybackManager] stopTrack];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadMoreTracks
{
    //Only load more tracks when searchresult is loaded
    if(self.searchResult == nil || ![self.searchResult isLoaded] || [self.searchResult hasExhaustedTrackResults])
        return;
    
    [self.searchResult addTrackPage];
    [SPAsyncLoading waitUntilLoaded:self.searchResult timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
     {
          if(loadedItems != nil && [loadedItems count] == 1 && [[loadedItems firstObject] isKindOfClass:[SPSearch class]])
              [self.tableView reloadData];
     }];
}

- (void) addSongButtonClicked:(id)sender
{
    TrackCell *trackCell = (TrackCell*)[Tools findSuperView:[TrackCell class] forView:(UIView *)sender];
    SPTrack *track = [self.searchResult.tracks objectAtIndex:[[self.tableView indexPathForCell:trackCell] row]];
    bool trackKnown = [songSearchDelegate isTrackAdded:track];
    
    // Notify delegate about track
    if(!trackKnown)
    {
        [self.songSearchDelegate trackAdded:track];
        [trackCell setAddMusicButton:RemoveMusic animated:YES];
        [Tools showCheckMarkHud:self.view text:@"Song added to alarm!"];
    }
    else
    {
        [self.songSearchDelegate trackRemoved:track];
        [trackCell setAddMusicButton:AddMusic animated:YES];
        [Tools showCheckMarkHud:self.view text:@"Song removed from alarm!"];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.searchResult != nil && [self.searchResult isLoaded])
    {
        if([self.searchResult hasExhaustedTrackResults])
            return [self.searchResult.tracks count];
        else
            return [self.searchResult.tracks count] + 1;
    }
    else
        return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([self.searchResult.tracks count] - 15 < [indexPath row])
    [self loadMoreTracks];
    
    //Show more cells loading cell
    if([self.searchResult.tracks count] == [indexPath row])
    {
        LoadMoreCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"loadingMoreCells" forIndexPath:indexPath];
        [cell.loadingText setText:@"Loading more tracks..."];
        [cell.spinner startAnimating];
        
        return cell;
    }
    else //Show track
    {
        SPTrack *track = [self.searchResult.tracks objectAtIndex:[indexPath row]];
        TrackCell *trackCell = [CellConstructHelper tableView:tableView cellForTrack:track atIndexPath:indexPath];
        [trackCell.btAddTrack addTarget:self action:@selector(addSongButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        if([songSearchDelegate isTrackAdded:track])
            [trackCell setAddMusicButton:RemoveMusic animated:NO];
        else
            [trackCell setAddMusicButton:AddMusic animated:NO];
        
        //Hide add/remove button when track not available
        if(track.availability != SP_TRACK_AVAILABILITY_AVAILABLE)
            [trackCell setAddMusicButton:hidden animated:NO];

        return trackCell;
    }
}

#pragma mark - UITableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self.searchResult.tracks count] == [indexPath row])
        return 40;
    else
        return 55;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SPTrack *track = [self.searchResult.tracks objectAtIndex:[indexPath row]];
    if([[SPPlaybackManager sharedPlaybackManager] currentTrack] == track)
        [[SPPlaybackManager sharedPlaybackManager] stopTrack];
    else
    {
        [[SPPlaybackManager sharedPlaybackManager] playTrack:track callback:^(NSError *error) {
            if(error != nil)
            {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Could not play track, error: %@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
                NSLog(@"AllTracksViewController could not play track, error: %@", [error localizedFailureReason]);
            }
        }];
    }
}


#pragma mark - SPPlackBackManager delegate
-(void)playbackManagerWillStartPlayingAudio:(SPPlaybackManager *)aPlaybackManager
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.searchResult.tracks indexOfObject:aPlaybackManager.currentTrack] inSection:0]];
    [cell showPlayProgress:YES animated:YES];
}
-(void)playbackManagerStoppedPlayingAudio:(SPPlaybackManager *)aPlaybackManager
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.searchResult.tracks indexOfObject:aPlaybackManager.currentTrack] inSection:0]];
    [cell showPlayProgress:NO animated:YES];
}

-(void)playbackManagerAudioProgress:(SPPlaybackManager *)aPlaybackManager progress:(double) progress
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.searchResult.tracks indexOfObject:aPlaybackManager.currentTrack] inSection:0]];
    [cell setProgress:progress];
}

-(void)playbackManagerDidEncounterStreamingError:(SPPlaybackManager *)aPlaybackManager error:(NSError *) error
{
    [[SPPlaybackManager sharedPlaybackManager] stopTrack];
    
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify Alarm Clock encountered a network error. Is your internet connection still active?" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
    NSLog(@"AllTracksViewController network error");
}

-(void)playbackManagerDidLosePlayToken:(SPPlaybackManager *)aPlaybackManager
{
    [[SPPlaybackManager sharedPlaybackManager] stopTrack];
    
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify track is playing on another device. Your account can only play tracks on one device at the same time." delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
    NSLog(@"AllTracksViewController did lose play token");
}

@end
