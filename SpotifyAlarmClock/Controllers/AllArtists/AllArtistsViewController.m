//
//  AllArtistsViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 04-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "AllArtistsViewController.h"
#import "CocoaLibSpotify.h"
#import "MBProgressHud.h"
#import "LoadMoreCell.h"
#import "ArtistCell.h"
#import "ArtistViewController.h"
#import "CellConstructHelper.h"

@interface AllArtistsViewController ()

@property (nonatomic, strong) SPSearch *searchResult;
@property (nonatomic, strong) ArtistBrowseCache *artistBrowseCache;

- (void)loadMoreArtists;

@end

@implementation AllArtistsViewController
@synthesize searchText;
@synthesize searchResult;
@synthesize artistBrowseCache;
@synthesize songSearchDelegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Register cells
    [self.tableView registerNib:[UINib nibWithNibName:@"ArtistCell" bundle:nil] forCellReuseIdentifier:@"artistCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"LoadMoreCell" bundle:nil] forCellReuseIdentifier:@"loadingMoreCells"];
    
    //Set up artist browse cache
    artistBrowseCache = [[ArtistBrowseCache alloc] init];
    [artistBrowseCache setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];  
    
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

- (void)loadMoreArtists
{
    //Only load more tracks when searchresult is loaded
    if(self.searchResult == nil || ![self.searchResult isLoaded] || [self.searchResult hasExhaustedArtistResults])
        return;
    
    [self.searchResult addArtistPage];
    [SPAsyncLoading waitUntilLoaded:self.searchResult timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
     {
         if(loadedItems != nil && [loadedItems count] == 1 && [[loadedItems firstObject] isKindOfClass:[SPSearch class]])
             [self.tableView reloadData];
     }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.searchResult != nil && [self.searchResult isLoaded])
    {
        if([self.searchResult hasExhaustedArtistResults])
            return [self.searchResult.artists count];
        else
            return [self.searchResult.artists count] + 1;
    }
    else
        return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Load more cells
    if([self.searchResult.artists count] - 20 < [indexPath row])
        [self loadMoreArtists];
    
    //More cells loading
    if([self.searchResult.artists count] == [indexPath row])
    {
        LoadMoreCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"loadingMoreCells" forIndexPath:indexPath];
        [cell.loadingText setText:@"Loading more artists..."];
        [cell.spinner startAnimating];
        
        return cell;
    }
    else //Show track
        return [CellConstructHelper tableView:tableView cellForArtist:[self.searchResult.artists objectAtIndex:[indexPath row]] atIndexPath:indexPath artistBrowseCache:artistBrowseCache];
}

#pragma mark - UITableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self.searchResult.artists count] == [indexPath row])
        return 40;
    else
        return 75;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if([self.searchResult.artists count] != [indexPath row])
        [self performSegueWithIdentifier:@"artistSegue" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"artistSegue"])
    {
        ArtistViewController *vw = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell*)sender];
        SPArtist *artist = [self.searchResult.artists objectAtIndex:[indexPath row]];
        [vw setArtistBrowse:[artistBrowseCache artistBrowseForArtist:artist]];
        [vw setSongSearchDelegate:self.songSearchDelegate];
    }
}

#pragma mark - ArtistBrowseCache delegate

- (void)artistPortraitLoaded:(UIImage *) artistPortrait artist:(SPArtist*)artist
{
    NSInteger indexOfArtist = [self.searchResult.artists indexOfObject:artist];
    if(indexOfArtist != NSNotFound)
    {
        ArtistCell * cell = (ArtistCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[searchResult.artists indexOfObject:artist] inSection:0]];
        [cell.artistImage setImage:artistPortrait];
    }
}

@end
