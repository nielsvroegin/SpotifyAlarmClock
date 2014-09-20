//
//  AlarmSong.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 20-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Alarm;

@interface AlarmSong : NSManagedObject

@property (nonatomic, retain) NSString * album;
@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSString * spotifyUrl;
@property (nonatomic, retain) NSString * trackName;
@property (nonatomic, retain) Alarm *alarm;

@end
