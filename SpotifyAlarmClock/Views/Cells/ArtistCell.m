//
//  ArtistCell.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 27-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "ArtistCell.h"

@implementation ArtistCell
@synthesize artistImage, lbArtist;

- (void)awakeFromNib {
    [artistImage layer].cornerRadius = [artistImage layer].frame.size.height /2;
    [artistImage layer].masksToBounds = YES;
    [artistImage layer].borderWidth = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
