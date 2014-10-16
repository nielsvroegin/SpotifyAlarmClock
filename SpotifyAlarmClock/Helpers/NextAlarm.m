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
+ (NSDate*) fixDateDuringWinterTimeTransistion:(NSDate*)potentialWinterTime;

@end

@implementation NextAlarm

+ (NSDateComponents*) provide
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSArray* alarms = [self getEnabledAlarms];
    
    //Return when no enabled alarms could be found
    if(alarms == nil || [alarms count] == 0)
        return nil;
    
    //Find next alarm for listed alarms
    NSDate* nextAlarm = nil;
    for(Alarm* alarm in alarms)
    {
        NSDate *nextAlarmForAlarm = [self nextAlarmForAlarm:alarm];
        
        if(nextAlarm == nil)
            nextAlarm = nextAlarmForAlarm;
        else
            nextAlarm = [nextAlarm earlierDate:nextAlarmForAlarm];
    }
    
    //Convert to DayOfWeek / Hour / Minute components because rest of NSDate information is not relevant
    return [gregorian components:(NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:nextAlarm];
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
            alarmDateCandidate = [self fixDateDuringWinterTimeTransistion:alarmDateCandidate];

            //Test candidate
            NSDateComponents * alarmDateCandidateComponents = [gregorian components:(NSHourCalendarUnit) fromDate:alarmDateCandidate];
            if(alarmDateCandidate != nil && [now compare:alarmDateCandidate] == NSOrderedAscending
               && alarmDateCandidateComponents.hour == [alarm.hour intValue]) //Skip when changing to summer time(in that case alarmDateCandidateComponents.hour will be one hour later)
                return alarmDateCandidate;
        }
    }
    
    return nil;
}

//This method will always return winter time, when date is during winter time transistion
//For example 26/10/2014 2:30 CEST will be converted to 26/10/2014 2:30 CET
//This will cause now < alarm to return true, when now = 26/10/2014 2:45 CEST and alarm = 26/10/2014 2:30
+(NSDate*) fixDateDuringWinterTimeTransistion:(NSDate*)potentialWinterTime
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
   
    //Add 1 hour to potential winter time
    NSDate * checkDate = [potentialWinterTime dateByAddingTimeInterval:(60 * 60)];
    
    //Retrieve hour component from both dates
    NSInteger potentialWinterTimeHour = [[gregorian components:(NSHourCalendarUnit) fromDate:potentialWinterTime] hour];
    NSInteger checkDateHour = [[gregorian components:(NSHourCalendarUnit) fromDate:checkDate] hour];
    
    //If hour component is still same, eventhough 1 hour has been added the date has been transform to winter and we will return that one
    if(potentialWinterTimeHour == checkDateHour)
        return checkDate;
    else
        return  potentialWinterTime;
}




@end
