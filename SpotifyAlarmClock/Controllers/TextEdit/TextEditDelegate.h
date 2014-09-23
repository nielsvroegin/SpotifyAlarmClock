//
//  TextEditDelegate.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 18-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TextEditViewController;

@protocol TextEditDelegate <NSObject>

- (void) textEditChanged:(TextEditViewController *)textEdit value:(NSString *)newValue;

@end
