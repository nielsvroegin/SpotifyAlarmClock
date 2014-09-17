//
//  OptionsSelectViewController.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 16-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OptionsSelectDelegate.h"

@interface OptionsSelectViewController : UITableViewController

@property (nonatomic, weak) id<OptionsSelectDelegate> delegate;
@property (nonatomic, strong) NSArray * options;

@end
