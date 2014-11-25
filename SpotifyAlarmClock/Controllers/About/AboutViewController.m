//
//  AboutViewController.m
//  Alarm Clock
//
//  Created by Niels Vroegindeweij on 31-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UILabel *lbVersion;

@end

@implementation AboutViewController
@synthesize lbVersion;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [lbVersion setText:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch ([indexPath row]) {
        case 2: //Linked In
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.linkedin.com/pub/niels-vroegindeweij/21/980/24b"]];
            break;
        case 3: //E-Mail
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://alarmclock.startsmart.nl"]];
            break;
    }
}


@end
