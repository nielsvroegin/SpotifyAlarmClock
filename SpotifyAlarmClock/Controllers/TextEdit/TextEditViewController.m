//
//  TextEditViewController.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 18-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "TextEditViewController.h"

@interface TextEditViewController ()

@property (nonatomic, strong) IBOutlet UITextField *txtField;

@end

@implementation TextEditViewController
@synthesize txtField;
@synthesize text;
@synthesize tag;
@synthesize delegate;
@synthesize autocapitalizationType;
@synthesize secureTextEntry;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [txtField setText:[self text]];
    [txtField setAutocapitalizationType:autocapitalizationType];
    [txtField setSecureTextEntry:secureTextEntry];
    [txtField becomeFirstResponder];
    
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark TextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.navigationController popViewControllerAnimated:YES];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [delegate textEditChanged:self value:textField.text];
}

@end
