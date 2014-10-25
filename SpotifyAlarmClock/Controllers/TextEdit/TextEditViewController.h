//
//  TextEditViewController.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 18-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextEditDelegate.h"

@interface TextEditViewController : UITableViewController<UITextFieldDelegate>

@property (nonatomic, weak) id<TextEditDelegate> delegate;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) NSUInteger tag;
@property (nonatomic, assign) BOOL secureTextEntry;
@property (nonatomic, assign) UITextAutocapitalizationType autocapitalizationType;

@end
