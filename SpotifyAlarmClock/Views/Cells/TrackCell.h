//
//  TrackCell.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 27-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum AddMusicButtonState : NSUInteger {
    hidden,
    AddMusic,
    RemoveMusic
} AddMusicButtonState;

@interface TrackCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lbTrack;
@property (weak, nonatomic) IBOutlet UILabel *lbArtist;
@property (weak, nonatomic) IBOutlet UIView *vwPlay;
@property (weak, nonatomic) IBOutlet UIButton *btAddTrack;

-(void) showPlayProgress:(bool)showPlayProgress;
-(void) showPlayProgress:(bool)showPlayProgress animated:(bool)animated;
-(void) setProgress:(CGFloat)progress;
-(void) setAddMusicButton:(AddMusicButtonState)addMusicButtonState animated:(bool)animated;

@end
