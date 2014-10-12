//
//  NSMutableArray (Convenience).m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 12-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "NSMutableArray+Convenience.h"

@implementation NSMutableArray (Convenience)

- (void)moveObjectAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    id object = [self objectAtIndex:fromIndex];
    [self removeObjectAtIndex:fromIndex];
    [self insertObject:object atIndex:toIndex];
}

@end
