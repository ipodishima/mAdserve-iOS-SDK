//
//  UIImage+AdSdk.h
//

#import <UIKit/UIKit.h>

@interface UIImage (AdSdk)

+ (UIImage*)adSdkImageNamed:(NSString*)name;
+ (UIImage *)adsdkAdCloseButtonImage;

+ (UIImage *)adsdkToolBarImage;
+ (UIImage *)adsdkBrowserForwardButtonImage;
+ (UIImage *)adsdkBrowserBackButtonImage;
+ (UIImage *)adsdkExportButtonImage;
+ (UIImage *)adsdkExportButtonDisabledImage;
+ (UIImage *)adsdkPauseButtonImage;
+ (UIImage *)adsdkPauseButtonDisabledImage;
+ (UIImage *)adsdkPlayButtonImage;
+ (UIImage *)adsdkPlayButtonDisabledImage;
+ (UIImage *)adsdkReplayButtonImage;
+ (UIImage *)adsdkReplayButtonDisabledImage;
+ (UIImage *)adsdkSkipButtonImage;
+ (UIImage *)adsdkSkipButtonDisabledImage;
+ (UIImage *)adsdkBrowserForwardButtonDisabledImage;
+ (UIImage *)adsdkBrowserBackButtonDisabledImage;

@end
