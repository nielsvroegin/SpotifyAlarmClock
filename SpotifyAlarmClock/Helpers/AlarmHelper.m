//
//  NextAlarm.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 14-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "AlarmHelper.h"
#import "Alarm.h"
#import "AppDelegate.h"

@interface AlarmHelper ()

+ (NSDate*)nextAlarmForAlarm:(Alarm*)alarm;
+ (NSArray*)getEnabledAlarms;
+ (NSDate*) fixDateDuringWinterTimeTransistion:(NSDate*)potentialWinterTime;
+ (NSArray *)removeExceededOneTimeAlarms:(NSArray *)alarms;

@end

@interface NextAlarm ()

@property (nonatomic, strong) NSDate * alarmDate;

@end

@implementation AlarmHelper

+ (NextAlarm*) provideNextAlarm
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSArray* alarms = [self getEnabledAlarms];
    
    // Return when no enabled alarms could be found
    if(alarms == nil || [alarms count] == 0)
        return nil;
    
    // Find next alarm for listed alarms
    NextAlarm* nextAlarm = [[NextAlarm alloc] init];
    NSMutableArray * backgroundAlarms = [[NSMutableArray alloc] initWithCapacity:[alarms count]];
    for(Alarm* alarm in alarms)
    {
        NSDate *nextAlarmForAlarm = [self nextAlarmForAlarm:alarm];
        [backgroundAlarms addObject:[NSArray arrayWithObjects:alarm, nextAlarmForAlarm, nil]];
        
        if(nextAlarm.alarm == nil || [nextAlarm.alarmDate compare:nextAlarmForAlarm] == NSOrderedDescending)
        {
            nextAlarm.alarm = alarm;
            nextAlarm.alarmDate = nextAlarmForAlarm;
        }
    }
    
    // Convert to DayOfWeek / Hour / Minute components because rest of NSDate information is not relevant
    if(nextAlarm.alarm != nil)
        nextAlarm.alarmDateComponents = [gregorian components:(NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:nextAlarm.alarmDate];
    
    return nextAlarm;
}

+ (void) configureBackgroundAlarms
{
    //Check if user notifications enabled
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)])
    {
        UIUserNotificationSettings * notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (!notificationSettings || (notificationSettings.types == UIUserNotificationTypeNone))
            return;
    }
    
    // Cancel current local notifications
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    //Don't add background alarms when disabled
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"BackgroundAlarm"])
        return;
    
    //Load enabled alarms
    NSArray* alarms = [self getEnabledAlarms];
    if(alarms == nil || [alarms count] == 0)
        return;
    
    // Schedule the notifications
    for(Alarm* alarm in alarms)
    {
        for(int i = 1; i <= 7; i++)
        {
            NSInteger testDayOnRepeat = ((i + 7 - 2) % 7);
            
            if([[alarm repeat] rangeOfString:[NSString stringWithFormat:@"%d", testDayOnRepeat]].location != NSNotFound || [[alarm repeat] length] == 0)
            {
                //Determine fire date for local notification
                NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                NSDate *now = [NSDate date];
                NSDateComponents *componentsForFireDate = [calendar components:(NSYearCalendarUnit | NSWeekCalendarUnit|  NSHourCalendarUnit | NSMinuteCalendarUnit| NSSecondCalendarUnit | NSWeekdayCalendarUnit) fromDate: now];
                [componentsForFireDate setWeekday: i];
                [componentsForFireDate setHour:[alarm.hour intValue]];
                [componentsForFireDate setMinute:[alarm.minute intValue]];
                [componentsForFireDate setSecond:0] ;
                NSDate *fireDateOfNotification = [calendar dateFromComponents: componentsForFireDate];
                
                //Set local notification
                NSDictionary * userInfo = [NSDictionary dictionaryWithObject:[[[alarm objectID] URIRepresentation] absoluteString] forKey:@"Alarm"];
                UILocalNotification* localNotification = [[UILocalNotification alloc] init];
                localNotification.fireDate = fireDateOfNotification;
                localNotification.repeatInterval = NSWeekCalendarUnit;
                localNotification.alertBody = @"Your alarm goes off!";
                localNotification.timeZone = [NSTimeZone defaultTimeZone];
                localNotification.soundName = @"background.mp3";
                localNotification.userInfo = userInfo;
                
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            }
        }
    }
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
    
    /****** remove exceeded one time alarms ******/
    alarms = [self removeExceededOneTimeAlarms:alarms];
    
    return alarms;
}

+ (NSArray *)removeExceededOneTimeAlarms:(NSArray *)alarms
{
    NSMutableArray * validAlarms = [[NSMutableArray alloc] init];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *now = [NSDate date];
    
    for(Alarm * alarm in alarms)
    {
        //Check alarm date on top of today, so we can see if alarm before or after now
        NSDateComponents * alarmComponents = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:now];
        alarmComponents.hour = [alarm.hour intValue];
        alarmComponents.minute = [alarm.minute intValue];
        NSDate * alarmDate = [gregorian dateFromComponents:alarmComponents];
        
        if([alarm repeat] == nil || [alarm.repeat length] > 0 || [alarmDate compare:now] == NSOrderedDescending || [alarm.lastEdited compare:alarmDate] == NSOrderedDescending)
            [validAlarms addObject:alarm];
        else
        {
            //------ Disable the Alarm ------//
            // Get refs to Managed object context
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *context = [appDelegate managedObjectContext];
            NSError *error;
            
            [alarm setEnabled:[NSNumber numberWithBool:NO]];
            
            // Save alarmData object
            if(![context save:&error])
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not disable non-repeating alarm!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil];
                [alert show];
                
                NSLog(@"Context save error: %@", error);
            }
        }

    }
    
    return validAlarms;
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

@implementation NextAlarm
@synthesize alarm;
@synthesize alarmDateComponents;
@synthesize alarmDate;
@end
