//
//  OptionSelectDelegate.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 16-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Option.h"

@protocol OptionsSelectDelegate <NSObject>

- (void)optionValueChanged:(Option *) option;

@end
