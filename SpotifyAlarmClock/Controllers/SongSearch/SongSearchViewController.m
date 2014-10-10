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
#import "AllTracksViewController.h"
#import "AllArtistsViewController.h"
#import "AllAlbumsViewController.h"
#import "ArtistViewController.h"
#import "CellConstructHelper.h"

@interface SongSearchViewController ()
    @property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
    @property (nonatomic, strong) SPSearch *searchResult;
    @property (nonatomic, strong) ArtistBrowseCache *artistBrowseCache;

    @property (atomic, assign) BOOL loading;
    @property (nonatomic, assign) NSInteger artistSection;
    @property (nonatomic, assign) NSInteger albumSection;
    @property (nonatomic, assign) NSInteger trackSection;

    - (void) performSearch;
@end

@implementation SongSearchViewController
@synthesize searchBar;
@synthesize searchResult;
@synthesize artistSection, albumSection, trackSection;
@synthesize artistBrowseCache;

- (void)viewDidLoad {
    //Register cells
    [self.tableView registerNib:[UINib nibWithNibName:@"AlbumCell" bundle:nil] forCellReuseIdentifier:@"albumCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ArtistCell" bundle:nil] forCellReuseIdentifier:@"artistCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"TrackCell" bundle:nil] forCellReuseIdentifier:@"trackCell"];
    
    
    //Set up artist browse cache
    artistBrowseCache = [[ArtistBrowseCache alloc] init];
    [artistBrowseCache setDelegate:self];
    
    //Show searchbar keyboard
    [searchBar becomeFirstResponder];

    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[SpotifyPlayer sharedSpotifyPlayer] setDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[SpotifyPlayer sharedSpotifyPlayer] stopTrack];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void) performSearch
{
    //Ignore search change when still loading
    if(self.loading)
        return;
    
    //Set loading and clean table
    self.loading = true;
    
    //Perform search
    SPSearch *search = [[SPSearch alloc] initWithSearchQuery:[self.searchBar text] pageSize:4 inSession:[SPSession sharedSession] type:SP_SEARCH_STANDARD];
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
         [artistBrowseCache clear];
         self.searchResult = search;
         [self.tableView reloadData];
         
         self.loading = false;
     }];
    
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
    [artistBrowseCache clear];
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
            cell = [CellConstructHelper tableView:tableView cellForTrack:[self.searchResult.tracks objectAtIndex:[indexPath row]] atIndexPath:indexPath];
    }
    else if(self.artistSection == indexPath.section)
    {
        if([indexPath row] == [self.searchResult.artists count])
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"allCell" forIndexPath:indexPath];
            [cell.textLabel setText:@"View all artists"];
        }
        else
            cell = [CellConstructHelper tableView:tableView cellForArtist:[self.searchResult.artists objectAtIndex:[indexPath row]] atIndexPath:indexPath artistBrowseCache:artistBrowseCache];
    }
    else if(self.albumSection == indexPath.section)
    {
        if([indexPath row] == [self.searchResult.albums count])
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"allCell" forIndexPath:indexPath];
            [cell.textLabel setText:@"View all albums"];
        }
        else
            cell = [CellConstructHelper tableView:tableView cellForAlbum:[self.searchResult.albums objectAtIndex:[indexPath row]] atIndexPath:indexPath artistNameOnTop:YES];
    }
    
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
        if([indexPath row] == [self.searchResult.tracks count])
            [self performSegueWithIdentifier:@"allTracksSegue" sender:nil];
        else
        {
            SPTrack *track = [self.searchResult.tracks objectAtIndex:[indexPath row]];
            if([[SpotifyPlayer sharedSpotifyPlayer] currentTrack] == track)
                [[SpotifyPlayer sharedSpotifyPlayer] stopTrack];
            else
                [[SpotifyPlayer sharedSpotifyPlayer] playTrack:track];
        }
    }
    else if(indexPath.section == artistSection)
    {
        if([indexPath row] == [self.searchResult.artists count])
            [self performSegueWithIdentifier:@"allArtistsSegue" sender:nil];
        else
            [self performSegueWithIdentifier:@"artistSegue" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
    }
    else if(indexPath.section == albumSection)
    {
        if([indexPath row] == [self.searchResult.albums count])
            [self performSegueWithIdentifier:@"allAlbumsSegue" sender:nil];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //First hide keyboard before performing segue
    if([self.searchBar isFirstResponder])
        [self.searchBar resignFirstResponder];
    
    
    if([[segue identifier] isEqualToString:@"allTracksSegue"])
    {
        AllTracksViewController *vw = [segue destinationViewController];
        [vw.navigationItem setTitle:[NSString stringWithFormat:@"Tracks for \"%@\"", [self.searchBar text]]];
        [vw setSearchText:[self.searchBar text]];
    }
    else if([[segue identifier] isEqualToString:@"allArtistsSegue"])
    {
        AllArtistsViewController *vw = [segue destinationViewController];
        [vw.navigationItem setTitle:[NSString stringWithFormat:@"Artists for \"%@\"", [self.searchBar text]]];
        [vw setSearchText:[self.searchBar text]];
    }
    else if([[segue identifier] isEqualToString:@"allAlbumsSegue"])
    {
        AllAlbumsViewController *vw = [segue destinationViewController];
        [vw.navigationItem setTitle:[NSString stringWithFormat:@"Albums for \"%@\"", [self.searchBar text]]];
        [vw setSearchText:[self.searchBar text]];
    }
    else if([[segue identifier] isEqualToString:@"artistSegue"])
    {
        ArtistViewController *vw = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell*)sender];
        SPArtist *artist = [self.searchResult.artists objectAtIndex:[indexPath row]];
        [vw setArtistBrowse:[artistBrowseCache artistBrowseForArtist:artist]];
    }
}

#pragma mark - Spotify Player delegate

- (void)track:(SPTrack *)track progess:(double) progress
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.searchResult.tracks indexOfObject:track] inSection:trackSection]];
    [cell setProgress:progress];
}

- (void)trackStartedPlaying:(SPTrack *)track
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.searchResult.tracks indexOfObject:track] inSection:trackSection]];
    [cell showPlayProgress:YES animated:YES];
}

- (void)trackStoppedPlaying:(SPTrack *)track
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.searchResult.tracks indexOfObject:track] inSection:trackSection]];
    [cell showPlayProgress:NO animated:YES];
}

#pragma mark - ArtistBrowseCache delegate

- (void)artistPortraitLoaded:(UIImage *) artistPortrait artist:(SPArtist*)artist
{
    NSInteger indexOfArtist = [self.searchResult.artists indexOfObject:artist];
    if(indexOfArtist != NSNotFound)
    {
        ArtistCell * cell = (ArtistCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[searchResult.artists indexOfObject:artist] inSection:artistSection]];
        [cell.artistImage setImage:artistPortrait];
    }
}

@end
