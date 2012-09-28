//
//  AdSdklNavigationBar.m
//

#import "AdSdkToolBar.h"

@implementation AdSdkToolBar

@synthesize backgroundImage;

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    
    if (self.backgroundImage) {
        [backgroundImage drawInRect: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) ];
    } else {
        [super drawRect:rect];
    }
    
}

@end
