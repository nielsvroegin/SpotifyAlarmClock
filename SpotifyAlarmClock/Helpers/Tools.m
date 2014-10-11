//
//  Tools.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 11-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "Tools.h"
#import "MBProgressHud.h"

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

@end
