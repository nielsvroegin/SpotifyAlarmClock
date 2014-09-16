//
//  Option.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 16-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Option : NSObject

@property (nonatomic, strong) NSString *label;
@property (nonatomic, assign) BOOL selected;

- initWithLabel:(NSString *)lb selected:(BOOL)sl;

@end
