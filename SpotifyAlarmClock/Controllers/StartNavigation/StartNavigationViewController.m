//
//  StartNavigationViewController.m
//  Alarm Clock
//
//  Created by Niels Vroegindeweij on 23-11-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "StartNavigationViewController.h"

@interface StartNavigationViewController ()

@end

@implementation StartNavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

@end
