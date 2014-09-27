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

@interface SongSearchViewController ()
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) SPSearch *searchResult;

@property (atomic, assign) BOOL loading;
@property (nonatomic, assign) NSInteger artistSection;
@property (nonatomic, assign) NSInteger albumSection;
@property (nonatomic, assign) NSInteger trackSection;

-(void) performSearch;

@end

@implementation SongSearchViewController
@synthesize searchBar;
@synthesize searchResult;
@synthesize artistSection, albumSection, trackSection;

- (void)viewDidLoad {
    [searchBar becomeFirstResponder];

    [super viewDidLoad];
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
    SPSearch *search = [[SPSearch alloc] initWithSearchQuery:[self.searchBar text] pageSize:5 inSession:[SPSession sharedSession]];
    [SPAsyncLoading waitUntilLoaded:search timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
     {
         //Disable loading HUD
         [MBProgressHUD hideAllHUDsForView:self.tableView animated:YES];
         
         //Check if search wasn't timed out
         if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPSearch class]])
         {
             [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify Alarm Clock wasn't able to perform the search. Is your internet connection still active?" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
             NSLog(@"Search request timedout");
         }
         
         //Check if search text still the same, otherwise redo search
         SPSearch *search = (SPSearch*)[loadedItems firstObject];
         if(![search.searchQuery isEqualToString:[self.searchBar text]])
         {
             self.loading = false;
             [self performSearch];
         }
         
         //Search successful, add to search result and reload table
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
    self.searchResult = nil;
    [self.tableView reloadData];
    
    //No need to search if searchtext is empty
    if([self.searchBar.text length] == 0)
        return;
    
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
        return [self.searchResult.tracks count];
    else if(self.artistSection == section)
        return [self.searchResult.artists count];
    else if(self.albumSection == section)
        return [self.searchResult.albums count];
    else
        return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if(self.trackSection == indexPath.section)
    {
        SPTrack *track = [self.searchResult.tracks objectAtIndex:[indexPath row]];
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"trackCell" forIndexPath:indexPath];
        [cell.textLabel setText:[track name]];
        [cell.detailTextLabel setText:[[[track artists] firstObject] name]];

    }
    else if(self.artistSection == indexPath.section)
    {
        SPArtist *artist = [self.searchResult.artists objectAtIndex:[indexPath row]];
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"trackCell" forIndexPath:indexPath];
        [cell.textLabel setText:[artist name]];
        [cell.detailTextLabel setText:@""];

    }
    else if(self.albumSection == indexPath.section)
    {
        SPAlbum *album = [self.searchResult.albums objectAtIndex:[indexPath row]];
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"trackCell" forIndexPath:indexPath];
        [cell.textLabel setText:[album.artist name]];
        [cell.detailTextLabel setText:[album name]];
    }
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([self.searchBar isFirstResponder])
        [self.searchBar resignFirstResponder];
    
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
