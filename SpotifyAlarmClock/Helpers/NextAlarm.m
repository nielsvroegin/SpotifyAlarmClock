//
//  NextAlarm.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 14-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "NextAlarm.h"
#import "Alarm.h"
#import "AppDelegate.h"

@interface NextAlarm ()

+ (NSDateComponents*)nextAlarmForAlarm:(Alarm*)alarm;
+ (NSArray*)getEnabledAlarms;

@end

@implementation NextAlarm

+ (NSDate*) provide
{
    NSArray* alarms = [self getEnabledAlarms];
    
    //Return when no enabled alarms could be found
    if(alarms == nil || [alarms count] == 0)
        return nil;
    
    NSDate* nextAlarm = nil;
    for(Alarm* alarm in alarms)
    {
        [self nextAlarmForAlarm:alarm];
        /*NSDate *nextAlarmForAlarm = [self nextAlarmForAlarm:alarm];
        
        if(nextAlarm == nil)
            nextAlarm = nextAlarmForAlarm;
        else
            nextAlarm = [nextAlarm earlierDate:nextAlarmForAlarm];*/
    }
    
    return nextAlarm;
}

+ (NSArray*)getEnabledAlarms
{
    NSArray* alarms;
    
    /****** Get refs to core date requirements ******/
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Alarm" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSError *error;
    
    /****** Fetch enabled alarms ******/
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"enabled = 1"]];
    alarms = [context executeFetchRequest:request error:&error];
    
    if(alarms == nil)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not load alarms, to determine next alarm!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil];
        [alert show];
        
        NSLog(@"Context fetch error: %@", error);
    }
    
    return alarms;
}

+ (NSDateComponents*)nextAlarmForAlarm:(Alarm*)alarm
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *now = [NSDate date];
    
    //------ Check next day of week to get on alarm time (today or tomorrow) ------/
    //1= sunday, 7 = saturday
    NSInteger weekDayPossibleAlarm = [[gregorian components:NSWeekdayCalendarUnit fromDate:now] weekday];
    
    NSDateComponents *currentHourMinute = [gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:now];
    NSDateComponents *alarmTimeHourMinute = [[NSDateComponents alloc] init];
    [alarmTimeHourMinute setHour:[[alarm hour] intValue]];
    [alarmTimeHourMinute setMinute:[[alarm minute] intValue]];
    
    NSDate * currentDate = [gregorian dateFromComponents:currentHourMinute];
    NSDate * alarmDate = [gregorian dateFromComponents:alarmTimeHourMinute];
    
    bool startToday = ([currentDate compare:alarmDate] == NSOrderedAscending);
    if(!startToday)
        weekDayPossibleAlarm = (weekDayPossibleAlarm +1) % 7;
    
    //------ Test days of week on alarm repeat settings ------//
    for(int i = 0; i < 7; i++)
    {
        NSInteger testDay = (weekDayPossibleAlarm + i) % 7;
        //For alarm.repeat Monday = 0 and Sunday=6, so convert test day
        NSInteger testDayOnRepeat = ((testDay + 7 - 2) % 7);
        
        if([[alarm repeat] rangeOfString:[NSString stringWithFormat:@"%d", testDayOnRepeat]].location != NSNotFound)
        {
            NSDateComponents *alarmTimeComponents = [[NSDateComponents alloc] init];
            alarmTimeComponents.hour = [[alarm hour] intValue];
            alarmTimeComponents.minute = [[alarm minute] intValue];
            alarmTimeComponents.weekday = testDay;

            return alarmTimeComponents;
        }
    }
    
    //If no tested successfully, this is a one time alarm. Set to first possible occurence
    NSDateComponents *alarmTimeComponents = [[NSDateComponents alloc] init];
    alarmTimeComponents.hour = [[alarm hour] intValue];
    alarmTimeComponents.minute = [[alarm minute] intValue];
    alarmTimeComponents.weekday = weekDayPossibleAlarm;
    
    return alarmTimeComponents;
}



@end
