//
//  SongsDelegate.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 11-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SongsDelegate <NSObject>

- (void) selectedSongsChanged:(NSArray*)tracks;

@end
