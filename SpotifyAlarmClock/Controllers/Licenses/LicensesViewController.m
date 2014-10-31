//
//  LicensesViewController.m
//  Alarm Clock
//
//  Created by Niels Vroegindeweij on 31-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "LicensesViewController.h"

@interface LicensesViewController ()
@property (weak, nonatomic) IBOutlet UITextView *tvLicenses;

@end

@implementation LicensesViewController
@synthesize tvLicenses;

- (void)viewDidLoad {
    [super viewDidLoad];

    NSURL *rtfPath = [[NSBundle mainBundle] URLForResource: @"licences" withExtension:@"rtf"];
    NSAttributedString *attributedStringWithRtf = [[NSAttributedString alloc]   initWithFileURL:rtfPath options:@{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType} documentAttributes:nil error:nil];
    self.tvLicenses.attributedText=attributedStringWithRtf;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
