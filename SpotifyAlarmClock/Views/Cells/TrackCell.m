//
//  TrackCell.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 27-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "TrackCell.h"

@implementation TrackCell
@synthesize lbArtist, lbTrack, vwPlay;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
