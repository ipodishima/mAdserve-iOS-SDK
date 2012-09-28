//
//  UIView+FindViewController.m
//

#import "UIView+FindViewController.h"


@implementation UIView (FindViewController)


- (UIViewController *) firstAvailableUIViewController
{
    return (UIViewController *)[self traverseResponderChainForUIViewController];
}

- (id) traverseResponderChainForUIViewController
{
	id nextResponder = [self nextResponder];
	if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [nextResponder traverseResponderChainForUIViewController];
    } else {
        return nil;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


@end

@implementation DummyView

@end