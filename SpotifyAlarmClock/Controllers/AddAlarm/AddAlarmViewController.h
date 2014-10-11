//
//  AddAlarmViewController.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 16-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OptionsSelectDelegate.h"
#import "TextEditDelegate.h"
#import "SongsDelegate.h"

@class Alarm;

@interface AddAlarmViewController : UITableViewController<OptionsSelectDelegate, TextEditDelegate, SongsDelegate>

@property (nonatomic, strong) Alarm *alarmData;

- (void)SaveAlarm;

@end
