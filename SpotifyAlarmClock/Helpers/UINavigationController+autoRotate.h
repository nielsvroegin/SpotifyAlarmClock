#import <UIKit/UIKit.h>

@interface UINavigationController (autoRotate)

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
-(BOOL)shouldAutorotate;
- (NSUInteger)supportedInterfaceOrientations;

@end