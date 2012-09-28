//
//  AdSdkVideoPlayerViewController.h
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MPMoviePlayerController.h>
#import "AdSdkToolBar.h"

@interface AdSdkVideoPlayerViewController : UIViewController

@property (nonatomic, strong) NSString *adVideoOrientation;

- (void)hideStatusBar;

@end
