//
//  AdSdkAdBrowserViewController.h
//

#import <UIKit/UIKit.h>

@class AdSdkAdBrowserViewController;

@protocol AdSdkAdBrowserViewController <NSObject>

- (void)adsdkAdBrowserControllerDidDismiss:(AdSdkAdBrowserViewController *)adsdkAdBrowserController;

@end



@interface AdSdkAdBrowserViewController : UIViewController <UIWebViewDelegate>
{
	UIWebView *_webView;
	NSURL *_url;
	
	NSString *userAgent;
	NSString *mimeType;
	NSString *textEncodingName;
	NSMutableData *receivedData;
	
    float buttonSize;
    
	__unsafe_unretained id <AdSdkAdBrowserViewController> delegate;
}

@property (nonatomic, strong) NSString *userAgent;
@property (nonatomic, readonly, strong) NSURL  *url;

@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, assign) __unsafe_unretained id <AdSdkAdBrowserViewController> delegate;

- (id)initWithUrl:(NSURL *)url;

@end
