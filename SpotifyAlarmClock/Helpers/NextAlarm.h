//
//  NextAlarm.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 14-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Alarm;

@interface NextAlarm : NSObject

+ (NextAlarm*) provide;

@property (nonatomic, strong) Alarm * alarm;
@property (nonatomic, strong) NSDateComponents * alarmDateComponents;

@end
