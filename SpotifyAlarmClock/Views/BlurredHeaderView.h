//
//  BlurredHeaderView.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 05-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlurredHeaderView : UIView
@property (weak, nonatomic) IBOutlet UIImageView *circularImage;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UILabel *artist;

@end
