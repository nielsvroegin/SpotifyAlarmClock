//
//  BackgroundGlow.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 13-10-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "BackgroundGlow.h"

@implementation BackgroundGlow

- (void) drawRect:(CGRect)rect
{
    //--------- Create image of oval ---------/
    CGContextRef cgContext = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(cgContext);
    UIGraphicsBeginImageContext(rect.size); //now it's here.
    
    //Oval shape
    UIColor* darkGreenColor = [UIColor colorWithRed: 0.051 green: 0.13 blue: 0.076 alpha: 1];
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect:rect];
    [darkGreenColor setFill];
    [ovalPath fill];
    
    //Create image from path
    CGContextAddPath(cgContext, ovalPath.CGPath);
    UIImage *ovalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsPopContext();
    UIGraphicsEndImageContext();
    
    //--------- Apply blur filter on image ---------/
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:ovalImage.CGImage];
    
    // setting up Gaussian Blur (we could use one of many filters offered by Core Image)
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:15.0f] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    //Change image size for good fit
    CGRect resizeRect = [inputImage extent];
    resizeRect.size.width += 10;
    resizeRect.size.height += 40;
    resizeRect.origin.x -= 5;
    resizeRect.origin.y -= 20;
    
    CGImageRef cgImage = [ciContext createCGImage:result fromRect:resizeRect];
    UIImage *blurredOvalImage = [UIImage imageWithCGImage:cgImage];//create a UIImage for this function to "return" so that ARC can manage the memory of the blur... ARC can't manage CGImageRefs so we need to release it before this function "returns" and ends.
    CGImageRelease(cgImage);//release CGIma
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
    [imageView setImage:blurredOvalImage];
    [imageView setContentMode:UIViewContentModeScaleAspectFill];
    
    [self addSubview:imageView];
}

@end
