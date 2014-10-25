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

+ (NSData *)dateForAlarmBackupSound:(NSUInteger)sound
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
