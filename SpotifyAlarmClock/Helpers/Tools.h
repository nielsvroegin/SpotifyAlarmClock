//
//  Tools.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 11-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Alarm;
@class AlarmSong;

@interface Tools : NSObject

+ (UIView*) findSuperView:(Class)typeOfView forView:(UIView*)view;
+ (void) showCheckMarkHud:(UIView*)targetView text:(NSString*)text;
+ (void)addCircleMaskToView:(UIView *)view;
+ (NSDate*)dateForHour:(NSInteger)hour andMinute:(NSInteger)minute;
+ (NSDateComponents*)hourAndMinuteForDate:(NSDate*)date;
+ (NSString *) shortWeekDaySymbolForUnit:(NSInteger) unit;
+ (NSData *)dataForAlarmBackupSound:(NSUInteger)sound;
+ (NSString *)dottedString:(NSString*)text;
+ (void) setSystemVolume:(float)volume;
+ (float) getSystemVolume;
+ (Alarm *) removeCorruptAlarmSong:(AlarmSong *) alarmSong fromAlarm:(Alarm *) alarm;

@end

@interface NSManagedObjectContext (FetchedObjectFromURI)
- (NSManagedObject *)objectWithURI:(NSURL *)uri;
@end