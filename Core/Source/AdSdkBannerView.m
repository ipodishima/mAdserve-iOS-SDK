//
//  AdSdkBannerView.m
//

#import "AdSdkBannerView.h"
#import "NSString+AdSdk.h"
#import "DTXMLDocument.h"
#import "DTXMLElement.h"
#import "UIView+FindViewController.h"
#import "NSURL+AdSdk.h"
#import "AdSdkAdBrowserViewController.h"
#import "RedirectChecker.h"
#import "UIDevice+IdentifierAddition.h"
#import "OpenUDID.h"

NSString * const AdSdkErrorDomain = @"AdSdk";

@interface AdSdkBannerView () {
}

@property (nonatomic, strong) NSString *userAgent;

@end

@implementation AdSdkBannerView
{
	RedirectChecker *redirectChecker;
}

- (void)setup
{
    
    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    self.userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    
    self.autoresizingMask = UIViewAutoresizingNone;
	self.backgroundColor = [UIColor clearColor];
	
	refreshAnimation = UIViewAnimationTransitionFlipFromLeft;
	
    self.allowDelegateAssigmentToRequestAd = YES;
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
	{
		[self setup];
    }
    return self;
}

- (void)awakeFromNib
{
	[self setup];
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

    delegate = nil;
	
	[_refreshTimer invalidate], _refreshTimer = nil;
}

#pragma mark Utilities

- (UIImage*)darkeningImageOfSize:(CGSize)size
{
	UIGraphicsBeginImageContext(size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	CGContextSetGrayFillColor(ctx, 0, 1);
	CGContextFillRect(ctx, CGRectMake(0, 0, size.width, size.height));
	
	UIImage *cropped = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return cropped;
}

- (NSURL *)serverURL
{
	return [NSURL URLWithString:self.requestURL];
}

#pragma mark Properties

- (void)setBounds:(CGRect)bounds
{
	[super setBounds:bounds];
	
	for (UIView *oneView in self.subviews)
	{
		oneView.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
	}
}

- (void)setTransform:(CGAffineTransform)transform
{
	[super setTransform:transform];
	
	for (UIView *oneView in self.subviews)
	{
		oneView.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
	}
}

- (void)setDelegate:(id <AdSdkBannerViewDelegate>)newDelegate
{
	if (newDelegate != delegate)
	{
		delegate = newDelegate;
		
		if (delegate)
		{
			if(self.allowDelegateAssigmentToRequestAd) {
                [self requestAd];
            }
		}
	} else {
        
    }
}

- (void)setRefreshTimerActive:(BOOL)active
{
    if (refreshTimerOff) {
        return;
        
    }
    
    BOOL currentlyActive = (_refreshTimer!=nil);
	
	if (active == currentlyActive)
	{
		return;
	}
	
	if (active && !bannerViewActionInProgress)
	{
		if (_refreshInterval)
		{
 
			_refreshTimer = [NSTimer scheduledTimerWithTimeInterval:_refreshInterval target:self selector:@selector(requestAd) userInfo:nil repeats:YES];

		}
	}
	else
	{
		[_refreshTimer invalidate], _refreshTimer = nil;
	}
}

- (void)hideStatusBar
{
	UIApplication *app = [UIApplication sharedApplication];
	
	if (!app.statusBarHidden)
	{
		if ([app respondsToSelector:@selector(setStatusBarHidden:withAnimation:)])
		{
			[app setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
		}
		else 
		{
			[app setStatusBarHidden:YES];
		}
		
		_statusBarWasVisible = YES;
	}
}

- (void)showStatusBarIfNecessary
{
	if (_statusBarWasVisible)
	{
		UIApplication *app = [UIApplication sharedApplication];
		
		if ([app respondsToSelector:@selector(setStatusBarHidden:withAnimation:)])
		{
			[app setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
		}
		else 
		{
			[app setStatusBarHidden:NO];
		}
	}
}

#pragma mark Ad Handling
- (void)reportSuccess
{
	bannerLoaded = YES;
	
	if ([delegate respondsToSelector:@selector(adsdkBannerViewDidLoadAdSdkAd:)])
	{
		[delegate adsdkBannerViewDidLoadAdSdkAd:self];
	}
}

- (void)reportRefresh
{
	
	if ([delegate respondsToSelector:@selector(adsdkBannerViewDidLoadRefreshedAd:)])
	{
		[delegate adsdkBannerViewDidLoadRefreshedAd:self];
	}
}

- (void)reportError:(NSError *)error
{
	bannerLoaded = NO;
	
	if ([delegate respondsToSelector:@selector(adsdkBannerView:didFailToReceiveAdWithError:)])
	{
		[delegate adsdkBannerView:self didFailToReceiveAdWithError:error];
	}
}

- (void)setupAdFromXml:(DTXMLDocument *)xml
{

	if ([xml.documentRoot.name isEqualToString:@"error"])
	{
		NSString *errorMsg = xml.documentRoot.text;
		
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:AdSdkErrorDomain code:AdSdkErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;	
	}
	
	
	NSArray *previousSubviews = [NSArray arrayWithArray:self.subviews];
	
	NSString *clickType = [xml.documentRoot getNamedChild:@"clicktype"].text;
	
	if ([clickType isEqualToString:@"inapp"])
	{
		_tapThroughLeavesApp = NO;
	}
	else
	{
		_tapThroughLeavesApp = YES;
	}
	
	NSString *clickUrlString = [xml.documentRoot getNamedChild:@"clickurl"].text;
	if ([clickUrlString length])
	{
		_tapThroughURL = [NSURL URLWithString:clickUrlString];
	}
	
	_shouldScaleWebView = [[xml.documentRoot getNamedChild:@"scale"].text isEqualToString:@"yes"];
	
	_shouldSkipLinkPreflight = [[xml.documentRoot getNamedChild:@"skippreflight"].text isEqualToString:@"yes"];
	
	UIView *newAdView = nil;
	
	NSString *adType = [xml.documentRoot.attributes objectForKey:@"type"];
	
	if ([adType isEqualToString:@"imageAd"]) 
	{
		if (!_bannerImage)
		{
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Error loading banner image" forKey:NSLocalizedDescriptionKey];
			
			NSError *error = [NSError errorWithDomain:AdSdkErrorDomain code:AdSdkErrorUnknown userInfo:userInfo];
			[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
			return;
		}
		
		CGFloat bannerWidth = [[xml.documentRoot getNamedChild:@"bannerwidth"].text floatValue];
		CGFloat bannerHeight = [[xml.documentRoot getNamedChild:@"bannerheight"].text floatValue];
		
		UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:CGRectMake(0, 0, bannerWidth, bannerHeight)];
		[button addTarget:self action:@selector(tapThrough:) forControlEvents:UIControlEventTouchUpInside];
		
		[button setImage:_bannerImage forState:UIControlStateNormal];
		button.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
		
		newAdView = button;
	}
	else if ([adType isEqualToString:@"textAd"]) 
	{
		NSString *html = [xml.documentRoot getNamedChild:@"htmlString"].text;
		
		CGSize bannerSize = CGSizeMake(320, 50);
		if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)
		{
			bannerSize = CGSizeMake(728, 90);
		}
		
		UIWebView *webView=[[UIWebView alloc]initWithFrame:CGRectMake(0, 0, bannerSize.width, bannerSize.height)];
		webView.delegate = (id)self;
		webView.userInteractionEnabled = NO;
		
		[webView loadHTMLString:html baseURL:nil];
		
		
		UIImage *grayingImage = [self darkeningImageOfSize:bannerSize];
		
		UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:webView.bounds];
		[button addTarget:self action:@selector(tapThrough:) forControlEvents:UIControlEventTouchUpInside];
		[button setImage:grayingImage forState:UIControlStateHighlighted];
		button.alpha = 0.47;
		
		button.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
		button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		
		[self addSubview:button];

		webView.backgroundColor = [UIColor clearColor];
		webView.opaque = NO;
		
		newAdView = webView;
	} 
	else if ([adType isEqualToString:@"noAd"]) 
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No inventory for ad request" forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:AdSdkErrorDomain code:AdSdkErrorInventoryUnavailable userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
	}
	else if ([adType isEqualToString:@"error"])
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:AdSdkErrorDomain code:AdSdkErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}
	else 
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unknown ad type '%@'", adType] forKey:NSLocalizedDescriptionKey];
		
		NSError *error = [NSError errorWithDomain:AdSdkErrorDomain code:AdSdkErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}
	
	if (newAdView)
	{
		
        newAdView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        if (CGRectEqualToRect(self.bounds, CGRectZero))
		{
			self.bounds = newAdView.bounds;
		}
		
		if ([previousSubviews count])
		{
			[UIView beginAnimations:@"flip" context:nil];
			[UIView setAnimationDuration:1.5];
			[UIView setAnimationTransition:refreshAnimation forView:self cache:NO];
		}
		
		[self insertSubview:newAdView atIndex:0];
		[previousSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
		
		if ([previousSubviews count]) {
			[UIView commitAnimations];

			[self performSelectorOnMainThread:@selector(reportRefresh) withObject:nil waitUntilDone:YES];
		} else {
			[self performSelectorOnMainThread:@selector(reportSuccess) withObject:nil waitUntilDone:YES];
		}
	}		
	
	_refreshInterval = [[xml.documentRoot getNamedChild:@"refresh"].text intValue];
	[self setRefreshTimerActive:YES];
}

- (void)asyncRequestAdWithPublisherId:(NSString *)publisherId
{
	@autoreleasepool 
	{
        NSString *mRaidCapable = @"0";
        
        NSString *requestType;
        if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)
        {
            requestType = @"iphone_app";
        }
        else
        {
            requestType = @"ipad_app";
        }
        
        NSString *osVersion = [UIDevice currentDevice].systemVersion;
        
        NSString *MD5MacAddress = [[UIDevice currentDevice] uniqueGlobalDeviceIdentifier];
        NSString *SHA1MacAddress = [[UIDevice currentDevice] uniqueGlobalDeviceIdentifierSHA1];
        
        NSString* openUDID = [OpenUDID value];

        NSString *requestString=[NSString stringWithFormat:@"c.mraid=%@&rt=%@&u=%@&o_mcmd5=%@&o_mcsha1=%@&o_openudid=%@&v=%@&s=%@&iphone_osversion=%@&spot_id=%@",
                                 [mRaidCapable stringByUrlEncoding],
                                 [requestType stringByUrlEncoding],
                                 [self.userAgent stringByUrlEncoding],
                                 [MD5MacAddress stringByUrlEncoding],
                                 [SHA1MacAddress stringByUrlEncoding],
                                 [openUDID stringByUrlEncoding],
                                 [SDK_VERSION stringByUrlEncoding],
                                 [publisherId stringByUrlEncoding],
                                 [osVersion stringByUrlEncoding],
                                 [advertisingSection?advertisingSection:@"" stringByUrlEncoding]];
        
        NSURL *serverURL = [self serverURL];

        if (!serverURL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Error - no or invalid requestURL. Please set requestURL" forKey:NSLocalizedDescriptionKey];
            
            NSError *error = [NSError errorWithDomain:AdSdkErrorDomain code:AdSdkErrorUnknown userInfo:userInfo];
            [self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
            return;
        }

        NSURL *url;
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?sdk=banner&%@", serverURL, requestString]];
        
        NSMutableURLRequest *request;
        NSError *error;
        NSURLResponse *response;
        NSData *dataReply;
        
        request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod: @"GET"];
        [request setValue:@"text/xml" forHTTPHeaderField:@"Accept"];
        [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
        
        dataReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        DTXMLDocument *xml = [DTXMLDocument documentWithData:dataReply];
        
        if (!xml)
        {		
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Error parsing xml response from server" forKey:NSLocalizedDescriptionKey];
            
            NSError *error = [NSError errorWithDomain:AdSdkErrorDomain code:AdSdkErrorUnknown userInfo:userInfo];
            [self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
            return;
        }
        
        NSString *bannerUrlString = [xml.documentRoot getNamedChild:@"imageurl"].text;
        
        if ([bannerUrlString length])
        {
            NSURL *bannerUrl = [NSURL URLWithString:bannerUrlString];
            _bannerImage = [[UIImage alloc]initWithData:[NSData dataWithContentsOfURL:bannerUrl]];
        }
        
        
        [self performSelectorOnMainThread:@selector(setupAdFromXml:) withObject:xml waitUntilDone:YES];
        
	}
    
}

- (void)showErrorLabelWithText:(NSString *)text
{
	UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
	label.numberOfLines = 0;
	label.backgroundColor = [UIColor whiteColor];
	label.font = [UIFont boldSystemFontOfSize:12];
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor redColor];
	
	label.text = text;
	
	[self addSubview:label];
}

- (void)requestAd
{
        
    if (!delegate)
	{
		[self showErrorLabelWithText:@"AdSdkBannerViewDelegate not set"];
		
		return;
	}
	
	if (![delegate respondsToSelector:@selector(publisherIdForAdSdkBannerView:)])
	{
		[self showErrorLabelWithText:@"AdSdkBannerViewDelegate does not implement publisherIdForAdSdkBannerView:"];
		
		return;
	}	
	
	
	NSString *publisherId = [delegate publisherIdForAdSdkBannerView:self];
	
	if (![publisherId length])
	{
		[self showErrorLabelWithText:@"AdSdkBannerViewDelegate returned invalid publisher ID."];
		
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Invalid publisher ID or Publisher ID not set" forKey:NSLocalizedDescriptionKey];
       
        NSError *error = [NSError errorWithDomain:AdSdkErrorDomain code:AdSdkErrorUnknown userInfo:userInfo];
        [self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}
	
	[self performSelectorInBackground:@selector(asyncRequestAdWithPublisherId:) withObject:publisherId];
}

#pragma mark Interaction

- (void)checker:(RedirectChecker *)checker detectedRedirectionTo:(NSURL *)redirectURL
{
	if ([redirectURL isDeviceSupported])
	{
		[[UIApplication sharedApplication] openURL:redirectURL];
		return;
	}
	
	UIViewController *viewController = [self firstAvailableUIViewController];
	
	AdSdkAdBrowserViewController *browser = [[AdSdkAdBrowserViewController alloc] initWithUrl:redirectURL];
	browser.delegate = (id)self;
	browser.userAgent = self.userAgent;
	browser.webView.scalesPageToFit = _shouldScaleWebView;
	
	[self hideStatusBar];

    if ([delegate respondsToSelector:@selector(adsdkBannerViewActionWillPresent:)])
    {
        [delegate adsdkBannerViewActionWillPresent:self];
    }

    [viewController presentModalViewController:browser animated:YES];
	
	bannerViewActionInProgress = YES;
}

- (void)checker:(RedirectChecker *)checker didFinishWithData:(NSData *)data
{
	UIViewController *viewController = [self firstAvailableUIViewController];
	
	AdSdkAdBrowserViewController *browser = [[AdSdkAdBrowserViewController alloc] initWithUrl:nil];
	browser.delegate = (id)self;
	browser.userAgent = self.userAgent;
	browser.webView.scalesPageToFit = _shouldScaleWebView;
	
	NSString *scheme = [_tapThroughURL scheme];
	NSString *host = [_tapThroughURL host];
	NSString *path = [[_tapThroughURL path] stringByDeletingLastPathComponent];
	
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@/", scheme, host, path]];
	
	
	[browser.webView loadData:data MIMEType:checker.mimeType textEncodingName:checker.textEncodingName baseURL:baseURL];
	
	[self hideStatusBar];

    if ([delegate respondsToSelector:@selector(adsdkBannerViewActionWillPresent:)])
    {
        [delegate adsdkBannerViewActionWillPresent:self];
    }

    [viewController presentModalViewController:browser animated:YES];
	
	bannerViewActionInProgress = YES;
}

- (void)checker:(RedirectChecker *)checker didFailWithError:(NSError *)error
{
	bannerViewActionInProgress = NO;
}

- (void)tapThrough:(id)sender
{
	if ([delegate respondsToSelector:@selector(adsdkBannerViewActionShouldBegin:willLeaveApplication:)])
	{
		BOOL allowAd = [delegate adsdkBannerViewActionShouldBegin:self willLeaveApplication:_tapThroughLeavesApp];
		
		if (!allowAd)
		{
			return;
		}
	}
	
	if (_tapThroughLeavesApp || [_tapThroughURL isDeviceSupported])
	{
        
        if ([delegate respondsToSelector:@selector(adsdkBannerViewActionWillLeaveApplication:)])
        {
            [delegate adsdkBannerViewActionWillLeaveApplication:self];
        }
        
        [[UIApplication sharedApplication]openURL:_tapThroughURL];
		return;
	}
	
	UIViewController *viewController = [self firstAvailableUIViewController];
	
	if (!viewController)
	{
		return;
	}
	
	[self setRefreshTimerActive:NO];
	
	if (!_shouldSkipLinkPreflight)
	{
		redirectChecker = [[RedirectChecker alloc] initWithURL:_tapThroughURL userAgent:self.userAgent delegate:(id)self];
		return;
	}
	
	AdSdkAdBrowserViewController *browser = [[AdSdkAdBrowserViewController alloc] initWithUrl:_tapThroughURL];
	browser.delegate = (id)self;
	browser.userAgent = self.userAgent;
	browser.webView.scalesPageToFit = _shouldScaleWebView;
	
	[self hideStatusBar];
	
    if ([delegate respondsToSelector:@selector(adsdkBannerViewActionWillPresent:)])
    {
        [delegate adsdkBannerViewActionWillPresent:self];
    }

    [viewController presentModalViewController:browser animated:YES];
	
	bannerViewActionInProgress = YES;
}

- (void)adsdkAdBrowserControllerDidDismiss:(AdSdkAdBrowserViewController *)adsdkAdBrowserController
{

    if ([delegate respondsToSelector:@selector(adsdkBannerViewActionWillFinish:)])
	{
		[delegate adsdkBannerViewActionWillFinish:self];
	}

    [self showStatusBarIfNecessary];
	[adsdkAdBrowserController dismissModalViewControllerAnimated:YES];
	
	bannerViewActionInProgress = NO;
	[self setRefreshTimerActive:YES];
	
	if ([delegate respondsToSelector:@selector(adsdkBannerViewActionDidFinish:)])
	{
		[delegate adsdkBannerViewActionDidFinish:self];
	}
}

#pragma mark WebView Delegate (Text Ads)

#pragma mark Notifications
- (void) appDidBecomeActive:(NSNotification *)notification
{
	[self setRefreshTimerActive:YES];
}

- (void) appWillResignActive:(NSNotification *)notification
{
	[self setRefreshTimerActive:NO];
}



@synthesize delegate;
@synthesize advertisingSection;
@synthesize bannerLoaded;
@synthesize bannerViewActionInProgress;
@synthesize refreshAnimation;
@synthesize refreshTimerOff;
@synthesize requestURL;
@synthesize allowDelegateAssigmentToRequestAd;
@synthesize userAgent;
@synthesize debugSecretKey;

@end

