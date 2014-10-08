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
#import "SpotifyPlayer.h"
#import "MBProgressHUD.h"
#import "LoadMoreCell.h"
#import "CellConstructHelper.h"

@interface AllTracksViewController ()

@property (nonatomic, strong) SPSearch *searchResult;

- (void)loadMoreTracks;

@end

@implementation AllTracksViewController
@synthesize searchText;

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
    
    [[SpotifyPlayer sharedSpotifyPlayer] setDelegate:self];
    
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
    
    [[SpotifyPlayer sharedSpotifyPlayer] stopTrack];
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
        LoadMoreCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"loadingMoreTracks" forIndexPath:indexPath];
        [cell.loadingText setText:@"Loading more tracks..."];
        [cell.spinner startAnimating];
        
        return cell;
    }
    else //Show track
        return [CellConstructHelper tableView:tableView cellForTrack:[self.searchResult.tracks objectAtIndex:[indexPath row]] atIndexPath:indexPath];
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
    if([[SpotifyPlayer sharedSpotifyPlayer] currentTrack] == track)
        [[SpotifyPlayer sharedSpotifyPlayer] stopTrack];
    else
        [[SpotifyPlayer sharedSpotifyPlayer] playTrack:track];
}


#pragma mark - Spotify Player delegate

#pragma mark - Spotify Player delegate

- (void)track:(SPTrack *)track progess:(double) progress
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.searchResult.tracks indexOfObject:track] inSection:0]];
    [cell setProgress:progress];
}

- (void)trackStartedPlaying:(SPTrack *)track
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.searchResult.tracks indexOfObject:track] inSection:0]];
    [cell showPlayProgress:YES animated:YES];
}

- (void)trackStoppedPlaying:(SPTrack *)track
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.searchResult.tracks indexOfObject:track] inSection:0]];
    [cell showPlayProgress:NO animated:YES];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
