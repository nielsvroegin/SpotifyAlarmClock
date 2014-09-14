//
//  SpotifyPlayer.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 08-10-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpotifyPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>


static SpotifyPlayer *SharedSpotifyPlayer;


@implementation SpotifyPlayer
@synthesize delegate;
@synthesize currentTrack;
@synthesize secondsPlayed;
@synthesize progressLastUpdated;




+(SpotifyPlayer*)sharedSpotifyPlayer
{
    if(SharedSpotifyPlayer == nil)
    {
        //Create new spotify player
        SharedSpotifyPlayer = [SpotifyPlayer new];
        
        //Set playback delegate of spotify session to this class
        [[SPSession sharedSession] setPlaybackDelegate:SharedSpotifyPlayer];
    
        //Initialize audio session       
        AudioSessionInitialize(NULL, NULL, NULL, NULL);
        
        UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
        AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                               sizeof(sessionCategory),
                                               &sessionCategory);
        
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
        
        AudioSessionSetActive(TRUE);
        
        //Init audio queue
        audio_init(SharedSpotifyPlayer.audiofifo);
    }
    
    return SharedSpotifyPlayer;
}



    
#pragma mark Audio Processing

-(audio_fifo_t*)audiofifo;
{
	return &audiofifo;
}

-(void) dealloc
{

}


-(void)playTrack:(SPTrack *)track;
{   
    //First stop playing track
    if(self.currentTrack != nil)
        [self stopTrack];
    
    //Play new track
    self.currentTrack = track;
    [[SPSession sharedSession] playTrack:self.currentTrack callback:nil];
    
    audio_start(self.audiofifo);
}


-(void)stopTrack
{
    //Stop playing
    [[SPSession sharedSession] unloadPlayback];

    audio_stop(self.audiofifo);
    
    //Reset progress vars
    self.secondsPlayed = 0;
    self.progressLastUpdated = 0;    
    
    //Call delegate
    if(delegate != nil)
        [delegate trackStoppedPlaying:self.currentTrack];
    
    //Set current track to nil
    self.currentTrack = nil;    
}

-(void)updateProgress
{
    [delegate track:self.currentTrack progess:(self.secondsPlayed / self.currentTrack.duration)];    
}






-(NSInteger)session:(SPSession *)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat {
    audio_fifo_t *af = self.audiofifo;
	audio_fifo_data_t *afd = NULL;
	size_t s;
    
	if (frameCount == 0)
		return 0; // Audio discontinuity, do nothing
    
    //Notify track is started
    if(self.secondsPlayed == 0 && delegate != nil)
        [delegate performSelectorOnMainThread:@selector(trackStartedPlaying:) withObject:self.currentTrack waitUntilDone:YES];
    
	pthread_mutex_lock(&af->mutex);
    
	// Buffer one second of audio
	if (af->qlen > audioFormat->sample_rate) {
		pthread_mutex_unlock(&af->mutex);
        
        return 0;
	}
    
	s = frameCount * sizeof(int16_t) * audioFormat->channels;
    
	afd = malloc(sizeof(audio_fifo_data_t) + s);
	memcpy(afd->samples, audioFrames, s);
    
	afd->nsamples = frameCount;
    
	afd->rate = audioFormat->sample_rate;
	afd->channels = audioFormat->channels;
    
	TAILQ_INSERT_TAIL(&af->q, afd, link);
	af->qlen += frameCount;
    
    //Calculate seconds played
    secondsPlayed += (double)frameCount / audioFormat->sample_rate;
    
    //Notify delegate about progress every second
    if((self.secondsPlayed - self.progressLastUpdated) > 1)
    {
        self.progressLastUpdated = self.secondsPlayed;
        [self performSelectorOnMainThread:@selector(updateProgress) withObject:nil waitUntilDone:NO];
    }
    
	pthread_cond_signal(&af->cond);
	pthread_mutex_unlock(&af->mutex);
    
	return frameCount;
    
}

- (void)session:(SPSession *)aSession didEncounterStreamingError:(NSError *)error
{
    [self stopTrack];
}

- (void)sessionDidEndPlayback:(SPSession *)aSession
{
    [self stopTrack];
}

- (void)sessionDidLosePlayToken:(SPSession *)aSession
{
    [self stopTrack];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Music stopped because your spotify account is used somewhere else." delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil];
    [alert show];
}

@end
