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
#import "MaskHelper.h"
#import "SpotifyPlayer.h"

@interface ArtistViewController ()

@property (nonatomic, strong) SPArtistBrowse *artistBrowse;
@property (nonatomic, strong) BlurredHeaderView *blurredHeaderView;

- (void)loadArtistBrowse;
- (TrackCell *)cellForTrackAtIndexPath:(NSIndexPath *)indexPath;


@end

@implementation ArtistViewController
@synthesize artist;
@synthesize artistBrowse;
@synthesize blurredHeaderView;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"BlurredHeader" owner:self options:nil];
    blurredHeaderView = [nibViews firstObject];
    
    [self.tableView addParallaxWithView:blurredHeaderView andHeight:220];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Set artist name
    [self.navigationItem setTitle:[artist name]];
    
    //Completely transparant navigationbar
    //[self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    //self.navigationController.navigationBar.shadowImage = [UIImage new];
    //self.navigationController.navigationBar.translucent = YES;
    //self.navigationController.view.backgroundColor = [UIColor clearColor];
    //self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        
    //Empty remaining search results
    self.artistBrowse = nil;
    [self.tableView reloadData];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    hud.labelText = @"Loading";
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:(24 / 255.0) green:(109 / 255.0) blue:(39 / 255.0) alpha:1];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self loadArtistBrowse];
}


- (void)loadArtistBrowse
{
    self.artistBrowse = [[SPArtistBrowse alloc] initWithArtist:artist inSession:[SPSession sharedSession] type:SP_ARTISTBROWSE_FULL];
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
              
              //Portrait
              [self.blurredHeaderView.circularImage setImage:[portrait image]];
              
              //Background portrait
              UIImage *blurredImage = [portrait.image applyBlurWithRadius:30 tintColor:[UIColor colorWithWhite:0.25 alpha:0.2] saturationDeltaFactor:1.5 maskImage:nil];
              [self.blurredHeaderView.backgroundImage setImage:blurredImage];
          }];
     }];
}

/*-(void)scrollViewDidScroll:(UIScrollView*)scrollView {
    
    CGRect initialFrame = CGRectMake(0, 0, 320, 160);
    
    if (scrollView.contentOffset.y < 0) {
        
        initialFrame.size.height =! scrollView.contentOffset.y;
        self.artistPortraitBackground.frame = initialFrame;
    }
}*/

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
    return [self cellForTrackAtIndexPath:indexPath];
}

- (TrackCell *)cellForTrackAtIndexPath:(NSIndexPath *)indexPath
{
    SPTrack *track = [self.artistBrowse.topTracks objectAtIndex:[indexPath row]];
    TrackCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"trackCell" forIndexPath:indexPath];
    
    NSString *artistsText = @"";
    for(NSInteger i = 0; i < [track.artists count]; i++)
    {
        artistsText = [artistsText stringByAppendingString:[[track.artists objectAtIndex:i] name]];
        if(i < ([track.artists count] -1))
            artistsText = [artistsText stringByAppendingString:@" - "];
    }
    [cell.lbArtist setText:artistsText];
    [cell.lbTrack setText:[track name]];
    [MaskHelper addCircleMaskToView:[cell vwPlay]];
    
    for(UIView* subView in [cell.vwPlay subviews])
        [subView removeFromSuperview];
    
    if([[SpotifyPlayer sharedSpotifyPlayer] currentTrack] == track)
        ;//[cell.vwPlay addSubview:musicProgressView];
    else
    {
        UIImageView* playImageView = [[UIImageView alloc] initWithFrame:[cell.vwPlay bounds]];
        [playImageView setImage:[UIImage imageNamed:@"Play"]];
        [cell.vwPlay addSubview:playImageView];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Top tracks";
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
