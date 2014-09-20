//
//  Alarm.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 20-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AlarmSong;

@interface Alarm : NSManagedObject

@property (nonatomic, retain) NSDate * AlarmTime;
@property (nonatomic, retain) NSNumber * Enabled;
@property (nonatomic, retain) NSString * Name;
@property (nonatomic, retain) NSString * Repeat;
@property (nonatomic, retain) NSNumber * Snooze;
@property (nonatomic, retain) NSSet *songs;
@end

@interface Alarm (CoreDataGeneratedAccessors)

- (void)addSongsObject:(AlarmSong *)value;
- (void)removeSongsObject:(AlarmSong *)value;
- (void)addSongs:(NSSet *)values;
- (void)removeSongs:(NSSet *)values;

@end
