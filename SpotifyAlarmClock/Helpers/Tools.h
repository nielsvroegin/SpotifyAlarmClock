//
//  Tools.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 11-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tools : NSObject

+ (UIView*) findSuperView:(Class)typeOfView forView:(UIView*)view;
+ (void) showCheckMarkHud:(UIView*)targetView text:(NSString*)text;
+ (void)addCircleMaskToView:(UIView *)view;
+ (NSDate*)dateForHour:(NSInteger)hour andMinute:(NSInteger)minute;
+ (NSDateComponents*)hourAndMinuteForDate:(NSDate*)date;
+ (NSString *) shortWeekDaySymbolForUnit:(NSInteger) unit;

@end
