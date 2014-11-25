//
//  LoginViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 25-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "LoginViewController.h"
#import "MBProgressHud.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *txtUsername;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet UIButton *btLogin;

- (IBAction)loginButtonClicked:(id)sender;
- (void) login;
- (IBAction)textValueChanged:(id)sender;
@end

@implementation LoginViewController
@synthesize txtUsername;
@synthesize txtPassword;
@synthesize btLogin;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Make navigationbar completely transculent
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    
    //Add background to table view
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LoginBackground"]];
    [tempImageView setFrame:self.tableView.frame];
    self.tableView.backgroundView = tempImageView;
    
    //Show keyboard
    [txtUsername becomeFirstResponder];
    
    //Set placeholders username/password
    txtUsername.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Spotify username or Facebook e-mail" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    txtPassword.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
    //Set delegates
    [txtUsername setDelegate:self];
    [txtPassword setDelegate:self];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[SPSession sharedSession] setDelegate:self];
    
    [btLogin setAlpha:0.5f];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[SPSession sharedSession] setDelegate:nil];
    
    [txtUsername resignFirstResponder];
    [txtPassword resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return NO;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void) login
{
    [txtUsername resignFirstResponder];
    [txtPassword resignFirstResponder];
    
    //Show loading HUD
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Logging In...";
    
    [[SPSession sharedSession] attemptLoginWithUserName:[txtUsername text] password:[txtPassword text]];
}

- (IBAction)loginButtonClicked:(id)sender
{
    [self login];
}

#pragma SPSessionDelegate methods

-(void)session:(SPSession *)aSession didGenerateLoginCredentials:(NSString *)credential forUserName:(NSString *)userName
{
    [[NSUserDefaults standardUserDefaults] setObject:userName forKey:@"SpotifyUsername"];
    [[NSUserDefaults standardUserDefaults] setObject:credential forKey:@"SpotifyPassword"];
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    NSString * errorMessage;
    switch ([error code])
    {
        case SP_ERROR_BAD_USERNAME_OR_PASSWORD:
            errorMessage = @"Your username and/or password was not accepted for login.";
            break;
        case SP_ERROR_USER_NEEDS_PREMIUM:
            errorMessage = @"Your Spotify account needs to be Premium.";
            break;
        case SP_ERROR_USER_BANNED:
            errorMessage = @"The specified Spotify account is banned.";
            break;
        case SP_ERROR_OTHER_PERMANENT:
            errorMessage = @"Could not login. Is your internet connection still active?";
            break;
        default:
            errorMessage = [error localizedDescription];
            break;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Spotify Login Failed"
                                                   message:errorMessage
                                                  delegate:self
                                         cancelButtonTitle:@"Oke"
                                          otherButtonTitles: nil];
    
    [alert show];
}

- (void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error
{
   [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Spotify Login Failed"
                                                    message:@"Could not check your credential due to a network error. Is your internet connection active?"
                                                   delegate:self
                                          cancelButtonTitle:@"Oke"
                                          otherButtonTitles: nil];
    
    [alert show];
}

- (IBAction)textValueChanged:(id)sender
{
    if([txtUsername.text length] > 0 && [txtPassword.text length] > 0)
    {
        [btLogin setAlpha:1.0f];
        [btLogin setEnabled:YES];
    }
    else
    {
        [btLogin setAlpha:0.5f];
        [btLogin setEnabled:NO];
    }
}



#pragma UITextField delegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == txtUsername)
        [txtPassword becomeFirstResponder];
    else if(textField == txtPassword)
    {
        if([txtUsername.text length] > 0 && [txtPassword.text length] > 0)
            [self login];
        else
            [txtUsername becomeFirstResponder];
    }
    
    return YES;
}

#pragma UITableView delegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}

@end
