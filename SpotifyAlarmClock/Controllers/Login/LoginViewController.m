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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardSpacingConstraint;
@property (weak, nonatomic) IBOutlet UITextField *txtUsername;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;

- (IBAction)loginButtonClicked:(id)sender;
- (IBAction)skipLoginButtonClicked:(id)sender;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void) login;
@end

@implementation LoginViewController
@synthesize keyboardSpacingConstraint;
@synthesize txtUsername;
@synthesize txtPassword;

- (void)observeKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Begin observing the keyboard notifications when the view is loaded.
    [self observeKeyboard];
    
    //Show keyboard
    [txtUsername becomeFirstResponder];
    
    //Set delegates
    [txtUsername setDelegate:self];
    [txtPassword setDelegate:self];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[SPSession sharedSession] setDelegate:self];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Spotify Usage"
                                                    message:@"This alarm clock allows you to select Spotify songs for the alarm function. To use the Spotify features a Spotify Premium account is required. Please specify how you want to proceed?"
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Use alarm clock without Spotify", @"Sign up for Spotify", @"Log in to Spotify",nil];
    [alert setTag:1];
    [alert show];
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
    //Show loading HUD
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Logging In...";
    
    [[SPSession sharedSession] attemptLoginWithUserName:[txtUsername text] password:[txtPassword text]];
}

- (IBAction)loginButtonClicked:(id)sender
{
    [self login];
}

- (IBAction)skipLoginButtonClicked:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Spotify Usage"
                                                   message:@"Are you sure you want to use the alarm clock without Spotify features? You can enter your credentials afterwards in the settings menu."
                                                  delegate:self
                                         cancelButtonTitle:@"No"
                                         otherButtonTitles:@"Yes",nil];
    [alert setTag:2];
    [alert show];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([alertView tag] == 1) //Spotify Usage alert
    {
        if (buttonIndex == 0)//Use alarm clock without Spotify
        {
            [self skipLoginButtonClicked:self];
        }
        else if (buttonIndex == 1)// Sign up for Spotify
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.spotify.com/nl/signup/"]];
        }
    }
    else if([alertView tag] == 2) //Skip Login alert
    {
        if (buttonIndex == [alertView firstOtherButtonIndex])
        {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"UseAlarmClockWithoutSpotify"];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}


- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];
    
    CGFloat height = keyboardFrame.size.height;
    
    self.keyboardSpacingConstraint.constant = height + 10;
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

#pragma UITextField delegate methods


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == txtUsername)
        [txtPassword becomeFirstResponder];
    else if(textField == txtPassword)
        [self login];
    
    return YES;
}

@end
