//
//  AlarmCell.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 20-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "AlarmCell.h"

@implementation AlarmCell
@synthesize lbTime;
@synthesize lbLabel;
@synthesize swAlarmEnabled;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
