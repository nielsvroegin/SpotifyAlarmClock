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
#import "AlbumCell.h"
#import "CellConstructHelper.h"
#import "AlbumViewController.h"
#import "Tools.h"

@interface ArtistViewController ()

@property (nonatomic, strong) SPArtist *artist;
@property (nonatomic, assign) bool headerRendered;
@property (nonatomic, strong) BlurredHeaderView *blurredHeaderView;
@property (nonatomic, assign) NSInteger singleSection;
@property (nonatomic, assign) NSInteger albumSection;
@property (nonatomic, assign) NSInteger trackSection;
@property (nonatomic, strong) NSArray *albums;
@property (nonatomic, strong) NSArray *singles;

- (void)loadArtistBrowse;
- (void)renderArtistHeader:(UIImage *)portrait;
- (void) addSongButtonClicked:(id)sender;

@end

@implementation ArtistViewController
@synthesize singleSection, albumSection, trackSection;
@synthesize artist;
@synthesize artistBrowse;
@synthesize blurredHeaderView;
@synthesize headerRendered;
@synthesize albums;
@synthesize singles;
@synthesize songSearchDelegate;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Register cells
    [self.tableView registerNib:[UINib nibWithNibName:@"TrackCell" bundle:nil] forCellReuseIdentifier:@"trackCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"AlbumCell" bundle:nil] forCellReuseIdentifier:@"albumCell"];
        
    //Load header view from nib
    NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"BlurredHeader" owner:self options:nil];
    blurredHeaderView = [nibViews firstObject];
    
    //Set header to max width
    CGRect frame = blurredHeaderView.frame;
    frame.size.width = self.view.bounds.size.width;
    blurredHeaderView.frame = frame;
    
    //Set default artistportrait
    [blurredHeaderView.image setImage:[UIImage imageNamed:@"ArtistPortrait"]];
    
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
    
    //Set artist by artistbrowse
    self.artist = [artistBrowse artist];
    
    //Set artist name
    [self.navigationItem setTitle:[artist name]];
    
    //Load artist information
    [self loadArtistBrowse];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[SPPlaybackManager sharedPlaybackManager] stopTrack];
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

         //Get albums/singles of artist
         albums = [self.artistBrowse.albums filteredArrayUsingPredicate:[NSPredicate predicateWithFormat: @"(type = %d OR type = %d) AND available = YES AND artist = %@", SP_ALBUMTYPE_ALBUM, SP_ALBUMTYPE_UNKNOWN, artist]];
         singles = [self.artistBrowse.albums filteredArrayUsingPredicate:[NSPredicate predicateWithFormat: @"type = %d AND available = YES AND artist = %@", SP_ALBUMTYPE_SINGLE, artist]];
         
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
    [UIView transitionWithView:self.blurredHeaderView.image
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [self.blurredHeaderView.image setImage:portrait];
                        [self.blurredHeaderView.image layer].cornerRadius = [self.blurredHeaderView.image layer].frame.size.height /2;
                        [self.blurredHeaderView.image layer].masksToBounds = YES;
                        [self.blurredHeaderView.image layer].borderWidth = 0;
                    } completion:NULL];
    
    headerRendered = true;
}

- (void) addSongButtonClicked:(id)sender
{
    TrackCell *trackCell = (TrackCell*)[Tools findSuperView:[TrackCell class] forView:(UIView *)sender];
    SPTrack *track = [self.artistBrowse.topTracks objectAtIndex:[[self.tableView indexPathForCell:trackCell] row]];
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
    //Hide results as long as no artist browse loaded;
    if(artistBrowse == nil || ![artistBrowse isLoaded])
        return 0;
    
    NSInteger sections = 0;
    
    if([[self.artistBrowse topTracks] count] > 0)
    {
        self.trackSection = sections;
        sections++;
    }
    else
        self.trackSection = -1;
    
    if([self.albums count] > 0)
    {
        self.albumSection = sections;
        sections++;
    }
    else
        self.albumSection = -1;
    
    if([self.singles count] > 0)
    {
        self.singleSection = sections;
        sections++;
    }
    else
        self.singleSection = -1;
    
    return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* sectionTitle;
    
    if(self.trackSection == section)
        sectionTitle = @"Top tracks";
    else if(self.albumSection == section)
        sectionTitle = @"Albums";
    else if(self.singleSection == section)
        sectionTitle = @"Singles";

    return sectionTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    
    if(section == trackSection)
    {
        rows = [artistBrowse.topTracks count];
        if (rows > 5) rows = 5;
    }
    else if(section == albumSection)
        rows = [albums count];
    else if(section == singleSection)
        rows = [singles count];
    
    return rows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    NSInteger section = [indexPath section];
    
    if(section == trackSection)
    {
        SPTrack *track = [self.artistBrowse.topTracks objectAtIndex:[indexPath row]];
        TrackCell *trackCell = [CellConstructHelper tableView:tableView cellForTrack:track atIndexPath:indexPath];
        [trackCell.btAddTrack addTarget:self action:@selector(addSongButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        if([songSearchDelegate isTrackAdded:track])
            [trackCell setAddMusicButton:RemoveMusic animated:NO];
        else
            [trackCell setAddMusicButton:AddMusic animated:NO];
        
        //Hide add/remove button when track not available
        if(track.availability != SP_TRACK_AVAILABILITY_AVAILABLE)
            [trackCell setAddMusicButton:hidden animated:NO];
        
        cell = trackCell;
    }
    else if(section == albumSection)
        cell = [CellConstructHelper tableView:tableView cellForAlbum:[self.albums objectAtIndex:[indexPath row]] atIndexPath:indexPath];
    else if(section == singleSection)
        cell = [CellConstructHelper tableView:tableView cellForAlbum:[self.singles objectAtIndex:[indexPath row]] atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - UITableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight;
    
    if(indexPath.section == trackSection)
        cellHeight = 55;
    else if(indexPath.section == albumSection)
        cellHeight = 75;
    else if(indexPath.section == singleSection)
        cellHeight = 75;
    
    return cellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.section == trackSection)
    {
        SPTrack *track = [self.artistBrowse.topTracks objectAtIndex:[indexPath row]];
        if([[SPPlaybackManager sharedPlaybackManager] currentTrack] == track)
            [[SPPlaybackManager sharedPlaybackManager] stopTrack];
        else
            [[SPPlaybackManager sharedPlaybackManager] playTrack:track callback:^(NSError *error) {
                if(error != nil)
                {
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Could not play track, error: %@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
                    NSLog(@"ArtistViewController could not play track, error: %@", [error localizedFailureReason]);
                }
            }];
    }
    else if(indexPath.section == albumSection || indexPath.section == singleSection)
        [self performSegueWithIdentifier:@"albumSegue" sender:[tableView cellForRowAtIndexPath:indexPath]];
}



#pragma mark - SPPlackBackManager delegate
-(void)playbackManagerWillStartPlayingAudio:(SPPlaybackManager *)aPlaybackManager
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.artistBrowse.topTracks indexOfObject:aPlaybackManager.currentTrack] inSection:0]];
    [cell showPlayProgress:YES animated:YES];
}
-(void)playbackManagerStoppedPlayingAudio:(SPPlaybackManager *)aPlaybackManager
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.artistBrowse.topTracks indexOfObject:aPlaybackManager.currentTrack] inSection:0]];
    [cell showPlayProgress:NO animated:YES];
}

-(void)playbackManagerAudioProgress:(SPPlaybackManager *)aPlaybackManager progress:(double) progress
{
    TrackCell *cell = (TrackCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.artistBrowse.topTracks indexOfObject:aPlaybackManager.currentTrack] inSection:0]];
    [cell setProgress:progress];
}

-(void)playbackManagerDidEncounterStreamingError:(SPPlaybackManager *)aPlaybackManager error:(NSError *) error
{
    [[SPPlaybackManager sharedPlaybackManager] stopTrack];
    
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify Alarm Clock encountered a network error. Is your internet connection still active?" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
    NSLog(@"ArtistViewController network error");
}

-(void)playbackManagerDidLosePlayToken:(SPPlaybackManager *)aPlaybackManager
{
    [[SPPlaybackManager sharedPlaybackManager] stopTrack];
    
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Spotify track is playing on another device. Your account can only play tracks on one device at the same time." delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
    NSLog(@"ArtistViewController did lose play token");
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"albumSegue"])
    {
        AlbumViewController *vw = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell*)sender];
        
        SPAlbum *album;
        if(indexPath.section == albumSection)
            album = [self.albums objectAtIndex:[indexPath row]];
        else if(indexPath.section == singleSection)
            album = [self.singles objectAtIndex:[indexPath row]];
        
        [vw setAlbum:album];
        [vw setSongSearchDelegate:self.songSearchDelegate];
    }
}

@end
