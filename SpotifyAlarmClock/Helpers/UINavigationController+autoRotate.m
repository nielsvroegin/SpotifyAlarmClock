#import "UINavigationController+autoRotate.h"

@implementation UINavigationController (autoRotate)

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [self.topViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (BOOL)shouldAutorotate
{
    return [self.visibleViewController shouldAutorotate];
}


- (NSUInteger)supportedInterfaceOrientations
{
    if (![[self.viewControllers lastObject] isKindOfClass:NSClassFromString(@"ViewController")])
    {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    else
    {
        return [self.topViewController supportedInterfaceOrientations];
    }
}

@end