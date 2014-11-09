//
//  AlbumViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 10-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "AlbumViewController.h"
#import "CocoaLibSpotify.h"
#import "MBProgressHud.h"
#import "UIImage+ImageEffects.h"
#import "UIScrollView+APParallaxHeader.h"
#import "BlurredHeaderView.h"
#import "TrackCell.h"
#import "AlbumCell.h"
#import "CellConstructHelper.h"
#import "Tools.h"

@interface AlbumViewController ()

@property (nonatomic, strong) SPAlbumBrowse *albumBrowse;
@property (nonatomic, assign) bool headerRendered;
@property (nonatomic, strong) BlurredHeaderView *blurredHeaderView;

- (void)loadAlbumBrowse;
- (void)renderAlbumHeader:(UIImage *)cover;
- (void) addSongButtonClicked:(id)sender;

@end

@implementation AlbumViewController
@synthesize album;
@synthesize albumBrowse;
@synthesize blurredHeaderView;
@synthesize headerRendered;
@synthesize songSearchDelegate;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Register cells
    [self.tableView registerNib:[UINib nibWithNibName:@"TrackCell" bundle:nil] forCellReuseIdentifier:@"trackCell"];
        
    //Load header view from nib
    NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"BlurredHeader" owner:self options:nil];
    blurredHeaderView = [nibViews firstObject];
    
    //Set header to max width
    CGRect frame = blurredHeaderView.frame;
    frame.size.width = self.view.bounds.size.width;
    blurredHeaderView.frame = frame;
    
    //Set default album image
    [blurredHeaderView.image setImage:[UIImage imageNamed:@"Album"]];
    
    //Add parallax header
    [self.tableView addParallaxWithView:blurredHeaderView andHeight:150];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Set Spotify Player delegate
    SPPlaybackManager * playBackManager = [SPPlaybackManager sharedPlaybackManager];
    [playBackManager setDelegate:self];
    
    //Set artist name
    [self.navigationItem setTitle:[album name]];
    
    //Load and render cover
    [album.cover startLoading];
    [SPAsyncLoading waitUntilLoaded:album.cover timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
     {
         if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPImage class]])
             return;
         
         SPImage *cover = (SPImage*)[loadedItems firstObject];
         
         [self renderAlbumHeader:[cover image]];
     }];
    
    //Load artist information
    [self loadAlbumBrowse];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //IOS 7 fix: http://stackoverflow.com/questions/25654850/uitableview-contentsize-zero-after-uiviewcontroller-updateviewconstraints-is-c
    [self.tableView reloadRowsAtIndexPaths:nil withRowAnimation:UITableViewRowAnimationNone];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[SPPlaybackManager sharedPlaybackManager] stopTrack];
}

- (void)loadAlbumBrowse
{
    //Show loading HUD
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    hud.labelText = @"Loading";
    
    //Async loading
    albumBrowse = [[SPAlbumBrowse alloc] initWithAlbum:album inSession:[SPSession sharedSession]];
    [SPAsyncLoading waitUntilLoaded:albumBrowse timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
     {
         //Check if databrowse could be loaded
         if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPAlbumBrowse class]])
         {
             [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify Alarm Clock wasn't able to load the album. Is your internet connection still active?" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
             NSLog(@"Album load time out");
             
             return;
         }
         
         //Disable loading HUD
         [MBProgressHUD hideAllHUDsForView:self.tableView animated:YES];
         
         //Reload table because artist browse was successful
         [self.tableView reloadData];
     }];
}

- (void)renderAlbumHeader:(UIImage*)cover
{
    //Only render header once
    if(headerRendered)
        return;
    
    //Background portrait
    UIImage *blurredImage = [cover applyBlurWithRadius:30 tintColor:[UIColor colorWithWhite:0.25 alpha:0.2] saturationDeltaFactor:1.5 maskImage:nil];
    [UIView transitionWithView:self.blurredHeaderView.backgroundImage
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [self.blurredHeaderView.backgroundImage setImage:blurredImage];
                    } completion:NULL];
    
    //Portrait
    [UIView transitionWithView:self.blurredHeaderView.image
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [self.blurredHeaderView.image setImage:cover];
                    } completion:NULL];
    
    headerRendered = true;
}

- (void) addSongButtonClicked:(id)sender
{
    TrackCell *trackCell = (TrackCell*)[Tools findSuperView:[TrackCell class] forView:(UIView *)sender];
    SPTrack *track = [self.albumBrowse.tracks objectAtIndex:[[self.tableView indexPathForCell:trackCell] row]];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //Hide results as long as no album browse loaded;
    if(albumBrowse == nil || ![albumBrowse isLoaded])
        return 0;
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return[self.albumBrowse.tracks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SPTrack *track = [self.albumBrowse.tracks objectAtIndex:[indexPath row]];
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

#pragma mark - UITableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    SPTrack *track = [self.albumBrowse.tracks objectAtIndex:[indexPath row]];
    if([[SPPlaybackManager sharedPlaybackManager] currentTrack] == track)
        [[SPPlaybackManager sharedPlaybackManager] stopTrack];
    else
    {
        [[SPPlaybackManager sharedPlaybackManager] playTrack:track callback:^(NSError *error) {
            if(error != nil)
            {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Could not play track, error: %@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
                NSLog(@"AlbumViewController could not play track, error: %@", [error localizedFailureReason]);
            }
        }];
    }
}


#pragma mark - SPPlackBackManager delegate
-(void)playbackManagerWillStartPlayingAudio:(SPPlaybackManager *)aPlaybackManager
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.albumBrowse.tracks indexOfObject:aPlaybackManager.currentTrack] inSection:0]];
    [cell showPlayProgress:YES animated:YES];
}
-(void)playbackManagerStoppedPlayingAudio:(SPPlaybackManager *)aPlaybackManager
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.albumBrowse.tracks indexOfObject:aPlaybackManager.currentTrack] inSection:0]];
    [cell showPlayProgress:NO animated:YES];
}

-(void)playbackManagerAudioProgress:(SPPlaybackManager *)aPlaybackManager progress:(double) progress
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.albumBrowse.tracks indexOfObject:aPlaybackManager.currentTrack] inSection:0]];
    [cell setProgress:progress];
}

-(void)playbackManagerDidEncounterStreamingError:(SPPlaybackManager *)aPlaybackManager error:(NSError *) error
{
    [[SPPlaybackManager sharedPlaybackManager] stopTrack];
    
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify Alarm Clock encountered a network error. Is your internet connection still active?" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
    NSLog(@"AlbumViewController network error");
}

-(void)playbackManagerDidLosePlayToken:(SPPlaybackManager *)aPlaybackManager
{
    [[SPPlaybackManager sharedPlaybackManager] stopTrack];
    
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify track is playing on another device. Your account can only play tracks on one device at the same time." delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
    NSLog(@"AlbumViewController did lose play token");
}

@end
