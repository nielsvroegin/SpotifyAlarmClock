//
//  ArtistViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 04-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "ArtistViewController.h"
#import "CocoaLibSpotify.h"
#import "MBProgressHud.h"
#import "UIImage+ImageEffects.h"
#import "UIScrollView+APParallaxHeader.h"
#import "BlurredHeaderView.h"
#import "TrackCell.h"
#import "SpotifyPlayer.h"
#import "CellConstructHelper.h"

@interface ArtistViewController ()

@property (nonatomic, strong) SPArtist *artist;
@property (nonatomic, assign) bool headerRendered;
@property (nonatomic, strong) BlurredHeaderView *blurredHeaderView;

- (void)loadArtistBrowse;
- (void)renderArtistHeader:(UIImage *)portrait;

@end

@implementation ArtistViewController
@synthesize artist;
@synthesize artistBrowse;
@synthesize blurredHeaderView;
@synthesize headerRendered;




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
    
    //Add parallax header
    [self.tableView addParallaxWithView:blurredHeaderView andHeight:220];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Set Spotify Player delegate
    [[SpotifyPlayer sharedSpotifyPlayer] setDelegate:self];
    
    //Set artist by artistbrowse
    self.artist = [artistBrowse artist];
    
    //Set artist name
    [self.navigationItem setTitle:[artist name]];
    
    //Load artist information
    [self loadArtistBrowse];
}

- (void)loadArtistBrowse
{
    //Show loading HUD
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    hud.labelText = @"Loading";
    
    //Async loading
    [SPAsyncLoading waitUntilLoaded:artistBrowse timeout:10.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems)
     {
         //Check if databrowse could be loaded
         if(loadedItems == nil || [loadedItems count] != 1 || ![[loadedItems firstObject] isKindOfClass:[SPArtistBrowse class]])
         {
             [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify Alarm Clock wasn't able to load the artist. Is your internet connection still active?" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
             NSLog(@"Artist load time out");
             
             return;
         }
         
         //Disable loading HUD
         [MBProgressHUD hideAllHUDsForView:self.tableView animated:YES];
         
         //Reload table because artist browse was successful
         [self.tableView reloadData];
         
         //Load portrait/first album image
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
              
              //Show artist header
              [self renderArtistHeader:[portrait image]];
          }];
     }];
}

- (void)renderArtistHeader:(UIImage*)portrait
{
    //Only render header once
    if(headerRendered)
        return;
    
    //Background portrait
    UIImage *blurredImage = [portrait applyBlurWithRadius:30 tintColor:[UIColor colorWithWhite:0.25 alpha:0.2] saturationDeltaFactor:1.5 maskImage:nil];
    [UIView transitionWithView:self.blurredHeaderView.backgroundImage
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [self.blurredHeaderView.backgroundImage setImage:blurredImage];
                    } completion:NULL];
    
    //Portrait
    [UIView transitionWithView:self.blurredHeaderView.circularImage
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [self.blurredHeaderView.circularImage setImage:portrait];
                    } completion:NULL];
    
    headerRendered = true;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //return [artistBrowse.albums count] + 1;
    if(artistBrowse != nil && [artistBrowse isLoaded])
        return 1;
    else
        return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    if(section == 0)
        return [artistBrowse.topTracks count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [CellConstructHelper tableView:tableView cellForTrack:[self.artistBrowse.topTracks objectAtIndex:[indexPath row]] atIndexPath:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Top tracks";
}

#pragma mark - UITableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
        return 55;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SPTrack *track = [self.artistBrowse.topTracks objectAtIndex:[indexPath row]];
    if([[SpotifyPlayer sharedSpotifyPlayer] currentTrack] == track)
        [[SpotifyPlayer sharedSpotifyPlayer] stopTrack];
    else
        [[SpotifyPlayer sharedSpotifyPlayer] playTrack:track];
}

#pragma mark - Spotify Player delegate

- (void)track:(SPTrack *)track progess:(double) progress
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.artistBrowse.topTracks indexOfObject:track] inSection:0]];
    [cell setProgress:progress];
}

- (void)trackStartedPlaying:(SPTrack *)track
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.artistBrowse.topTracks indexOfObject:track] inSection:0]];
    [cell showPlayProgress:YES animated:YES];
}

- (void)trackStoppedPlaying:(SPTrack *)track
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.artistBrowse.topTracks indexOfObject:track] inSection:0]];
    [cell showPlayProgress:NO animated:YES];
}

@end
