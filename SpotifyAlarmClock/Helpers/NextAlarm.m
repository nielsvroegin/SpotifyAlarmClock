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

+ (NSDate*)nextAlarmForAlarm:(Alarm*)alarm;
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
        NSDate *nextAlarmForAlarm = [self nextAlarmForAlarm:alarm];
        
        if(nextAlarm == nil)
            nextAlarm = nextAlarmForAlarm;
        else
            nextAlarm = [nextAlarm earlierDate:nextAlarmForAlarm];
    }
    
    
    //TEST
    /*NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    
    NSDateComponents *adayComponent = [[NSDateComponents alloc] init];
    adayComponent.year = 2014;
    adayComponent.month = 3;
    adayComponent.day = 29;
    adayComponent.hour = 3;
    adayComponent.minute = 0;
    NSDate * aDay = [gregorian dateFromComponents:adayComponent];
    
    NSDate * nextDay1 = [aDay dateByAddingTimeInterval:60*60*24*1];
    NSDate * nextDay2 = [gregorian dateByAddingComponents:dayComponent toDate:aDay options:0];*/
    
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

+ (NSDate*)nextAlarmForAlarm:(Alarm*)alarm
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *now = [NSDate date];
    NSInteger currentWeekDay = [[gregorian components:NSWeekdayCalendarUnit fromDate:now] weekday];
    
    
    //------ Test days of week on alarm repeat settings ------//
    for(int i = 0; i < 14; i++)
    {
        NSInteger testDay = currentWeekDay + i;
        NSInteger testDayOnRepeat = ((testDay + 7 - 2) % 7);
        
        if([[alarm repeat] rangeOfString:[NSString stringWithFormat:@"%d", testDayOnRepeat]].location != NSNotFound || [[alarm repeat] length] == 0)
        {
            //------- Next alarm candidate -------//
            //Prepare required data for calculation
            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
            dayComponent.day = i;
            NSDateComponents * todayMidnightComponents = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:now];
            NSDate * todayMidnight = [gregorian dateFromComponents:todayMidnightComponents];
            NSDate * alarmMidnight = [gregorian dateByAddingComponents:dayComponent toDate:todayMidnight options:0];
            
            //Create candidate
            NSDateComponents * alarmComponents = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:alarmMidnight];
            alarmComponents.hour = [alarm.hour intValue];
            alarmComponents.minute = [alarm.minute intValue];
            NSDate * alarmDateCandidate = [gregorian dateFromComponents:alarmComponents];

            //Test candidate
            NSDateComponents * alarmDateCandidateComponents = [gregorian components:(NSHourCalendarUnit) fromDate:alarmDateCandidate];
            if(alarmDateCandidate != nil && [now compare:alarmDateCandidate] == NSOrderedAscending && alarmDateCandidateComponents.hour == [alarm.hour intValue])
                return alarmDateCandidate;
        }
    }
    
    return nil;
}




@end
