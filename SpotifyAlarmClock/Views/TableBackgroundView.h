//
//  TableBackgroundView.h
//  Alarm Clock
//
//  Created by Niels Vroegindeweij on 03-11-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableBackgroundView : UIView

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpaceConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;


@end
