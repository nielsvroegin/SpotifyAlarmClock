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

@interface ArtistViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *artistPortrait;
@property (weak, nonatomic) IBOutlet UIImageView *artistPortraitBackground;
@property (nonatomic, strong) SPArtistBrowse *artistBrowse;
@property (weak, nonatomic) IBOutlet UILabel *artistName;
@property (weak, nonatomic) IBOutlet UIView *containerArtistPortrait;
//@property (nonatomic, assign) CGRect initialHeaderFrame;


- (void)loadArtistBrowse;



@end

@implementation ArtistViewController
@synthesize artist;
@synthesize artistName;
@synthesize containerArtistPortrait;
@synthesize artistPortrait, artistPortraitBackground;
@synthesize artistBrowse;
//@synthesize initialHeaderFrame;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Set artist name
    [self.artistName setText:[artist name]];
    
    //Completely transparant navigationbar
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    //Bottom border
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, containerArtistPortrait.frame.size.height, containerArtistPortrait.frame.size.width, 1.0f);
    bottomBorder.backgroundColor = [UIColor blackColor].CGColor;
    [containerArtistPortrait.layer addSublayer:bottomBorder];
    
    //Empty remaining search results
    self.artistBrowse = nil;
    [self.tableView reloadData];
    
    //initialHeaderFrame = containerArtistPortrait.frame;
    
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

/*-(void)scrollViewDidScroll:(UIScrollView*)scrollView {
    if(scrollView.contentOffset.y < 0) {
        scrollView.contentInset = UIEdgeInsetsMake(scrollView.contentOffset.y, 0, 0, 0);
        CGRect newFrame = CGRectMake(0, 0, initialHeaderFrame.size.width, initialHeaderFrame.size.height - scrollView.contentOffset.y) ;
        containerArtistPortrait.frame = newFrame;
    }
}*/


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
              self.artistPortrait.contentMode = UIViewContentModeScaleAspectFill;
              [self.artistPortrait layer].cornerRadius = [self.artistPortrait layer].frame.size.height /2;
              [self.artistPortrait layer].masksToBounds = YES;
              [self.artistPortrait layer].borderWidth = 0;
              [self.artistPortrait setImage:[portrait image]];
              
              //Background portrait
              UIImage *blurredImage = [portrait.image applyBlurWithRadius:30 tintColor:[UIColor colorWithWhite:0.25 alpha:0.2] saturationDeltaFactor:1.5 maskImage:nil];
              self.artistPortraitBackground.contentMode = UIViewContentModeScaleToFill;
              [self.artistPortraitBackground setImage:blurredImage];

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
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
