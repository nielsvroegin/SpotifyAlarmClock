//
//  LoginViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 25-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardSpacingConstraint;
@property (weak, nonatomic) IBOutlet UITextField *txtUsername;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;

- (IBAction)loginButtonClicked:(id)sender;
- (IBAction)skipLoginButtonClicked:(id)sender;
- (void)keyboardWillShow:(NSNotification *)notification;
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
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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

// The callback for frame-changing of keyboard
- (IBAction)loginButtonClicked:(id)sender {
}

- (IBAction)skipLoginButtonClicked:(id)sender {
    [txtUsername resignFirstResponder];
    [txtPassword resignFirstResponder];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];
    
    CGFloat height = keyboardFrame.size.height;
    
    self.keyboardSpacingConstraint.constant = height + 40;
}


@end
