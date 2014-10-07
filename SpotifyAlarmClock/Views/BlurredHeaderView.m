//
//  BlurredHeaderView.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 05-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "BlurredHeaderView.h"

@implementation BlurredHeaderView
@synthesize backgroundImage, circularImage;


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    //Set content mode / Create circular mask for circular image
    self.circularImage.contentMode = UIViewContentModeScaleAspectFill;
    [self.circularImage layer].cornerRadius = [self.circularImage layer].frame.size.height /2;
    [self.circularImage layer].masksToBounds = YES;
    [self.circularImage layer].borderWidth = 0;
    
    //Set content mode background image
    self.backgroundImage.contentMode = UIViewContentModeScaleToFill;
}


@end
