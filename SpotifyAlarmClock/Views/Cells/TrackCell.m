//
//  TrackCell.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 27-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "TrackCell.h"
#import "FFCircularProgressView.h"
#import "Tools.h"

@interface TrackCell ()

@property (nonatomic, strong) FFCircularProgressView *musicProgressView;

-(void)switchPlayView:(bool)showPlayProgress;

@end

@implementation TrackCell
@synthesize lbArtist, lbTrack, vwPlay, btAddTrack;
@synthesize musicProgressView;

- (void)awakeFromNib {
    [Tools addCircleMaskToView:vwPlay];
    
    [self setAddMusicButton:AddMusic animated:false];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void) showPlayProgress:(bool)showPlayProgress
{
    [self showPlayProgress:showPlayProgress animated:NO];
}

-(void) showPlayProgress:(bool)showPlayProgress animated:(bool)animated
{
    if(animated)
    {
        [UIView transitionWithView:vwPlay
                          duration:1.0
                           options:UIViewAnimationOptionTransitionFlipFromRight | UIViewAnimationOptionShowHideTransitionViews
                        animations:^{
                            [self switchPlayView:showPlayProgress];
                        } completion:nil];
    }
    else
        [self switchPlayView:showPlayProgress];
    
}

-(void)switchPlayView:(bool)showPlayProgress
{
    [musicProgressView setProgress:0.01];
    
    for(UIView* subView in [vwPlay subviews])
        [subView removeFromSuperview];
    
    if(showPlayProgress)
    {
        if(musicProgressView == nil)
        {
            musicProgressView = [[FFCircularProgressView alloc] initWithFrame:[vwPlay bounds]];
            [musicProgressView setTintColor:[UIColor colorWithRed:(24 / 255.0) green:(109 / 255.0) blue:(39 / 255.0) alpha:1]];
        }
        [vwPlay addSubview:musicProgressView];
    }
    else
    {
        UIImageView* playImageView = [[UIImageView alloc] initWithFrame:[vwPlay bounds]];
        [playImageView setImage:[UIImage imageNamed:@"Play"]];
        [vwPlay addSubview:playImageView];
    }
}


-(void) setAddMusicButton:(AddMusicButtonState)addMusicButtonState animated:(bool)animated
{
    UIImage *newImage;
    UIImage *newImageHighlighted;
    UIImage *currentImage = self.btAddTrack.imageView.image;
    
    //Determine new images
    switch(addMusicButtonState)
    {
        case hidden:
            newImage = nil;
            newImageHighlighted = nil;
            break;
        case AddMusic:
            newImage = [UIImage imageNamed:@"AddMusicButton"];
            newImageHighlighted = [UIImage imageNamed:@"AddMusicButtonClicked"];
            break;
        case RemoveMusic:
            newImage = [UIImage imageNamed:@"RemoveMusicButton"];
            newImageHighlighted = [UIImage imageNamed:@"RemoveMusicButtonClicked"];
            break;
    }
    
    //Set new images
    [self.btAddTrack setImage:newImage forState:UIControlStateNormal];
    [self.btAddTrack setImage:newImage forState:UIControlStateHighlighted];
    [self.btAddTrack setImage:newImageHighlighted forState:UIControlStateSelected];
    
    
    //Animate transistion
    if(animated)
    {
        NSArray *animationImages = [[NSArray alloc] initWithObjects:currentImage, [UIImage imageNamed:@"IntermediateMusicButton"], newImage, nil];
        [self.btAddTrack.imageView setAnimationImages:animationImages];
        [self.btAddTrack.imageView setAnimationDuration:0.1];
        [self.btAddTrack.imageView setAnimationRepeatCount:1];
        
        [self.btAddTrack.imageView startAnimating];
    }
}

-(void) setProgress:(CGFloat)progress
{
    if(progress >= 1.0) progress = 0.999;
    [musicProgressView setProgress:progress];
}

@end
