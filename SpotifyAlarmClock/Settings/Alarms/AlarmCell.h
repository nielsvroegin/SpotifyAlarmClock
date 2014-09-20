//
//  AlarmCell.h
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 20-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlarmCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *lbTime;
@property (weak, nonatomic) IBOutlet UILabel *lbLabel;
@property (weak, nonatomic) IBOutlet UISwitch *swAlarmEnabled;

@end
