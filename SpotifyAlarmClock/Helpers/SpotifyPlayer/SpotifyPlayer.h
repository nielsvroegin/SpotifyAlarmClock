//
//  SpotifyPlayer.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 08-10-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CocoaLibSpotify.h"
#import "audio.h"


@protocol SpotifyPlayerDelegate;

@interface SpotifyPlayer : NSObject <SPSessionDelegate, SPSessionPlaybackDelegate>
{
    @private
        SPTrack *currentTrack;
        audio_fifo_t audiofifo;
        NSObject<SpotifyPlayerDelegate> *delegate;
        double secondsPlayed;
        NSInteger progressLastUpdated;


}


@property (readonly) audio_fifo_t *audiofifo;
@property (nonatomic, retain) SPTrack *currentTrack;
@property (nonatomic, retain) NSObject<SpotifyPlayerDelegate> *delegate;
@property (nonatomic, assign) double secondsPlayed;
@property (nonatomic, assign) NSInteger progressLastUpdated;



+(SpotifyPlayer*)sharedSpotifyPlayer;
-(void)openSessionWithUsername:(NSString *)username Password:(NSString *)password;
-(void)playTrack:(SPTrack *)track;
-(void)stopTrack;
-(void)updateProgress;

@end

@protocol SpotifyPlayerDelegate

- (void)track:(SPTrack *)track progess:(double) progress;
- (void)trackStartedPlaying:(SPTrack *)track;
- (void)trackStoppedPlaying:(SPTrack *)track;

@end

