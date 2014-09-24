//
//  SongSearchViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 23-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "SongSearchViewController.h"
#import "CocoaLibSpotify.h"

@interface SongSearchViewController ()
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) SPSearch *searchResult;
@property (nonatomic, strong) SPSearch *search;

@property (nonatomic, assign) NSInteger artistSection;
@property (nonatomic, assign) NSInteger albumSection;
@property (nonatomic, assign) NSInteger trackSection;

@end

@implementation SongSearchViewController
@synthesize searchBar;
@synthesize search, searchResult;
@synthesize artistSection, albumSection, trackSection;

- (void)viewDidLoad {
    [searchBar becomeFirstResponder];

    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"search.loaded"])
    {
        if([self.search isLoaded])
        {
            [self removeObserver:self forKeyPath:@"search.loaded"];
            self.searchResult = self.search;
            self.search = nil;
            
            [self.tableView reloadData];
        }
    }
}

#pragma mark - Searchbar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
    
    [self addObserver:self forKeyPath:@"search.loaded" options:0 context:nil];
    self.search = [[SPSearch alloc] initWithSearchQuery:[self.searchBar text] pageSize:5 inSession:[SPSession sharedSession]];
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
