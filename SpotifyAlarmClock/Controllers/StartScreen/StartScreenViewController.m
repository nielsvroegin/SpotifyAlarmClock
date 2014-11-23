//
//  StartScreenViewController.m
//  Alarm Clock
//
//  Created by Niels Vroegindeweij on 23-11-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "StartScreenViewController.h"

@interface StartScreenViewController ()

- (IBAction)skipLoginButtonClicked:(id)sender;

@end

@implementation StartScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LoginBackground"]];
    [tempImageView setFrame:self.tableView.frame];
   
    self.tableView.backgroundView = tempImageView;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    [[UIDevice currentDevice] setValue:
     [NSNumber numberWithInteger: UIInterfaceOrientationPortrait]
                                forKey:@"orientation"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}



- (IBAction)skipLoginButtonClicked:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Spotify Usage"
                                                   message:@"Are you sure you want to use the Alarm Clock without Spotify features? You can enter your credentials afterwards in the settings menu."
                                                  delegate:self
                                         cancelButtonTitle:@"No"
                                         otherButtonTitles:@"Yes",nil];
    [alert show];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView firstOtherButtonIndex])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"UseAlarmClockWithoutSpotify"];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch ([indexPath row]) {
        case 1: //Linked In
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.spotify.com/nl/signup/"]];
    }
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}
@end
