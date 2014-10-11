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
    
    //Load tracks for alarm songs
    [self LoadTracks];
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
    return [CellConstructHelper tableView:self.tableView cellForTrack:[tracks objectAtIndex:[indexPath row]] atIndexPath:indexPath];
}

#pragma mark - UITableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
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


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"songSearchSegue"])
    {
        SongSearchViewController *vw = (SongSearchViewController*)[[segue destinationViewController] topViewController];
        [vw setSongSearchDelegate:self];
    }
}

@end
