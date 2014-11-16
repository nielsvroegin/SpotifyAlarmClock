//
//  Tools.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 11-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "Tools.h"
#import "MBProgressHud.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Alarm.h"
#import "AlarmSong.h"
#import "AppDelegate.h"

@implementation Tools

+ (UIView*) findSuperView:(Class)typeOfView forView:(UIView*)view
{
    while(![view isKindOfClass:typeOfView] && view != nil)
        view = [view superview];
    
    return view;
}

+ (void) showCheckMarkHud:(UIView*)targetView text:(NSString*)text
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:targetView animated:YES];
    hud.mode = MBProgressHUDModeCustomView;
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark"]];
    hud.progress = 1.0f;
    hud.labelText = text;
    [hud hide:YES afterDelay:1.0f];
}

+ (void)addCircleMaskToView:(UIView *)view {
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = view.bounds;
    maskLayer.path = [UIBezierPath bezierPathWithOvalInRect:view.bounds].CGPath;
    maskLayer.fillColor = [UIColor whiteColor].CGColor;
    view.layer.mask = maskLayer;
}

+ (NSDate*)dateForHour:(NSInteger)hour andMinute:(NSInteger)minute
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents * comps = [[NSDateComponents alloc] init];
    [comps setHour:hour];
    [comps setMinute:minute];
    return [gregorian dateFromComponents:comps];
}

+ (NSDateComponents*)hourAndMinuteForDate:(NSDate*)date
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    return [gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
}

+ (NSString *) shortWeekDaySymbolForUnit:(NSInteger) unit
{
    switch(unit)
    {
        case 1:
            return @"SU";
        case 2:
            return @"MO";
        case 3:
            return @"TU";
        case 4:
            return @"WE";
        case 5:
            return @"TH";
        case 6:
            return @"FR";
        case 7:
            return @"SA";
        default:
            return @"";
    }
}

+ (NSData *)dataForAlarmBackupSound:(NSUInteger)sound
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSString *filePath = nil;
    switch(sound)
    {
        case 0:
            filePath = [mainBundle pathForResource:@"day-by-day" ofType:@"mp3"];
            break;
        case 1:
            filePath = [mainBundle pathForResource:@"forever" ofType:@"mp3"];
            break;
        case 2:
            filePath = [mainBundle pathForResource:@"alpha-beta" ofType:@"mp3"];
            break;
    }
    
    return [NSData dataWithContentsOfFile:filePath];
}

+ (NSString *)dottedString:(NSString*)text
{
    // self.password is your password string
    NSMutableString *dottedPassword = [[NSMutableString alloc] init];
    
    for (NSUInteger i = 0; i < [text length]; i++)
    {
        [dottedPassword appendString:@"●"]; // BLACK CIRCLE Unicode: U+25CF, UTF-8: E2 97 8F
    }
    
    return dottedPassword;
}

+ (Alarm *) removeCorruptAlarmSong:(AlarmSong *) alarmSong fromAlarm:(Alarm *) alarm
{
    /****** Get refs to Managed object context ******/
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSError *error;
    
    [context deleteObject:alarmSong];
    
    /****** Save alarmData object ******/
    if(![context save:&error])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not remove not playbable song from Alarm!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil];
        [alert show];
        
        NSLog(@"Context save error: %@", error);
    }
    
    [context refreshObject:alarm mergeChanges:NO];
    
    return alarm;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
+ (void) setSystemVolume:(float)volume {
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:volume];
}
#pragma GCC diagnostic pop

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
+ (float) getSystemVolume {
    return [[MPMusicPlayerController applicationMusicPlayer] volume];
}
#pragma GCC diagnostic pop

@end

@implementation NSManagedObjectContext (FetchedObjectFromURI)
- (NSManagedObject *)objectWithURI:(NSURL *)uri
{
    NSManagedObjectID *objectID =
    [[self persistentStoreCoordinator]
     managedObjectIDForURIRepresentation:uri];
    
    if (!objectID)
    {
        return nil;
    }
    
    NSManagedObject *objectForID = [self objectWithID:objectID];
    if (![objectForID isFault])
    {
        return objectForID;
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[objectID entity]];
    
    // Equivalent to
    // predicate = [NSPredicate predicateWithFormat:@"SELF = %@", objectForID];
    NSPredicate *predicate =
    [NSComparisonPredicate
     predicateWithLeftExpression:
     [NSExpression expressionForEvaluatedObject]
     rightExpression:
     [NSExpression expressionForConstantValue:objectForID]
     modifier:NSDirectPredicateModifier
     type:NSEqualToPredicateOperatorType
     options:0];
    [request setPredicate:predicate];
    
    NSArray *results = [self executeFetchRequest:request error:nil];
    if ([results count] > 0 )
    {
        return [results objectAtIndex:0];
    }
    
    return nil;
}
@end
