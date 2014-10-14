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

@property (nonatomic, retain) NSNumber * hour;
@property (nonatomic, retain) NSNumber * minute;
@property (nonatomic, retain) NSNumber * enabled;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * repeat;
@property (nonatomic, retain) NSNumber * snooze;
@property (nonatomic, retain) NSOrderedSet *songs;
@end

@interface Alarm (CoreDataGeneratedAccessors)

- (void)addSongsObject:(AlarmSong *)value;
- (void)removeSongsObject:(AlarmSong *)value;
- (void)addSongs:(NSSet *)values;
- (void)removeSongs:(NSSet *)values;

@end
