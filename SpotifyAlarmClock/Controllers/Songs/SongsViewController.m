//
//  SongsViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 23-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "SongsViewController.h"
#import "CocoaLibSpotify.h"
#import "SongSearchViewController.h"
#import "AlarmSong.h"
#import "CellConstructHelper.h"
#import "MBProgressHUD.h"
#import "TrackCell.h"
#import "NSMutableArray+Convenience.h"

@interface SongsViewController ()

@property (nonatomic, strong) NSMutableArray* tracks;
@property (nonatomic, assign) NSInteger missingTracksCount;

- (void) LoadTracks;
-(void) updateLoadingProgress;

@end

@implementation SongsViewController
@synthesize delegate;
@synthesize tracks;
@synthesize alarmSongs;
@synthesize missingTracksCount;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    tracks = [[NSMutableArray alloc] init];
    
    //Registers cell nibs
    [self.tableView registerNib:[UINib nibWithNibName:@"TrackCell" bundle:nil] forCellReuseIdentifier:@"trackCell"];
    
    //Set tableview in edit mode and allow row selecting
    [self.tableView setEditing:YES];
    [self.tableView setAllowsSelectionDuringEditing:YES];
    
    //Load tracks for alarm songs
    [self LoadTracks];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[SpotifyPlayer sharedSpotifyPlayer] setDelegate:self];
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

- (void) LoadTracks
{
    //Check if any tracks should be loaded
    if([self.alarmSongs count] == 0)
        return;
    
    //Show loading HUD
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    hud.mode = MBProgressHUDModeDeterminate;
    hud.progress = 0;
    hud.labelText = @"Loading";
    
    for(AlarmSong *alarmSong in alarmSongs)
    {
        [[SPSession sharedSession] trackForURL:[NSURL URLWithString:alarmSong.spotifyUrl] callback:^(SPTrack *track){
            if (track == nil)
            {
                missingTracksCount++;
                [self updateLoadingProgress];
            }
            
            [SPAsyncLoading waitUntilLoaded:track timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems)
            {
                if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPTrack class]])
                {
                    [MBProgressHUD hideAllHUDsForView:self.tableView animated:YES];
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify Alarm Clock wasn't able to load track. Is your internet connection still active?" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
                    return;
                }
                
                [tracks addObject:track];
                
                [self updateLoadingProgress];
            }];
        }];
    }
}

-(void) updateLoadingProgress
{
    //Update progress
    [[MBProgressHUD HUDForView:self.tableView] setProgress:(1 * ((tracks.count + missingTracksCount) / alarmSongs.count))];
    
    //Check if all loaded
    if((tracks.count + missingTracksCount) == alarmSongs.count)
    {
        [MBProgressHUD hideAllHUDsForView:self.tableView animated:YES];
        [self.tableView reloadData];
    }
}

- (IBAction)unwindToSongs:(UIStoryboardSegue *)unwindSegue { }


#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tracks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TrackCell *cell = [CellConstructHelper tableView:self.tableView cellForTrack:[tracks objectAtIndex:[indexPath row]] atIndexPath:indexPath];
    [cell setAddMusicButton:hidden animated:NO];
    cell.showsReorderControl = YES;

    
    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    //Movie track
    [self.tracks moveObjectAtIndex:[fromIndexPath row] toIndex:[toIndexPath row]];

    //Notify delegate
    [delegate selectedSongsChanged:self.tracks];
}

#pragma mark - UITableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SPTrack *track = [self.tracks objectAtIndex:[indexPath row]];
    if([[SpotifyPlayer sharedSpotifyPlayer] currentTrack] == track)
        [[SpotifyPlayer sharedSpotifyPlayer] stopTrack];
    else
        [[SpotifyPlayer sharedSpotifyPlayer] playTrack:track];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Check if editing style is delete
    if(editingStyle != UITableViewCellEditingStyleDelete)
        return;
    
    //If current playing track will be delete stop playing track
    if([[SpotifyPlayer sharedSpotifyPlayer] currentTrack] == [self.tracks objectAtIndex:[indexPath row]])
        [[SpotifyPlayer sharedSpotifyPlayer] stopTrack];
    
    //Remove track
    [self.tracks removeObjectAtIndex:[indexPath row]];
    
    //Notify delegate
    [delegate selectedSongsChanged:self.tracks];
    
    //Animate table with change
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

#pragma mark - Song Search delegate
- (void)trackAdded:(SPTrack *)track
{
    //Add track
    [self.tracks addObject:track];
    
    //Notify delegate
    [delegate selectedSongsChanged:self.tracks];
    
    //Reload table
    [self.tableView reloadData];
}

- (void)trackRemoved:(SPTrack *)track
{
    //Add track
    [self.tracks removeObject:track];
    
    //Notify delegate
    [delegate selectedSongsChanged:self.tracks];
    
    //Reload table
    [self.tableView reloadData];
}

- (bool)isTrackAdded:(SPTrack *)track
{
    return [self.tracks containsObject:track];
}

#pragma mark - Spotify Player delegate

- (void)track:(SPTrack *)track progess:(double) progress
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.tracks indexOfObject:track] inSection:0]];
    [cell setProgress:progress];
}

- (void)trackStartedPlaying:(SPTrack *)track
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.tracks indexOfObject:track] inSection:0]];
    [cell showPlayProgress:YES animated:YES];
}

- (void)trackStoppedPlaying:(SPTrack *)track
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.tracks indexOfObject:track] inSection:0]];
    [cell showPlayProgress:NO animated:YES];
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"songSearchSegue"])
    {
        SongSearchViewController *vw = (SongSearchViewController*)[[segue destinationViewController] topViewController];
        [vw setSongSearchDelegate:self];
    }
}

@end
