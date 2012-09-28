//
//  UIView+FindViewController.h
//

#import <UIKit/UIKit.h>


@interface UIView (FindViewController)

- (UIViewController *) firstAvailableUIViewController;
- (id) traverseResponderChainForUIViewController;

@end

@interface DummyView : UIView

@end