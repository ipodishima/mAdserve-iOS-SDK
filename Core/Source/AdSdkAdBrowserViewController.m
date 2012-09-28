//
//  AdSdkAdBrowserViewController.m
//

#import "AdSdkAdBrowserViewController.h"

#import "NSURL+AdSdk.h"
#import "UIImage+AdSdk.h"

@interface AdSdkAdBrowserViewController ()

@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSString *textEncodingName;
@property (nonatomic, strong) NSURL *url;

@end



@implementation AdSdkAdBrowserViewController

@synthesize url = _url;
@synthesize userAgent;
@synthesize receivedData;
@synthesize mimeType;
@synthesize textEncodingName;
@synthesize webView = _webView;

@synthesize delegate;


- (id)initWithUrl:(NSURL *)url
{
	if (self = [super init])
	{
		self.url = url;
	}
	
	return self;
}

- (void)dealloc 
{
	delegate = nil;
}


- (void)loadView
{
    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)
    {
        buttonSize = 30.0f;
    }
    else
    {
        buttonSize = 50.0f;
    }

    CGRect mainFrame = [UIScreen mainScreen].applicationFrame;
	
	self.view = [[UIView alloc] initWithFrame:mainFrame];
	
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	self.webView.frame = self.view.bounds;
	[self.view addSubview:self.webView];
	
	
	UIImage *image = [UIImage adsdkSkipButtonImage];
	
    float skipButtonSize = buttonSize +4.0f;

	UIButton *btnClose=[UIButton buttonWithType:UIButtonTypeCustom];
	[btnClose setImage:image forState:UIControlStateNormal];
	[btnClose addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
	[btnClose setFrame:CGRectMake(self.view.bounds.size.width - (skipButtonSize+10.0f), 10, skipButtonSize, skipButtonSize)];
	btnClose.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
	[self.view addSubview:btnClose];
	
}

- (UIWebView *)webView
{
	if (!_webView)
	{
		_webView = [[UIWebView alloc] initWithFrame:CGRectZero];
		_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_webView.delegate = self;
	}
	
	return _webView;
}


- (void)loadURL:(NSURL *)url
{
	
	if (!_url)
	{
		self.url = url;
		return;
	}
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	
	
	if (userAgent)
	{
		[request addValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
		
		NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
		[connection start];
		[self webViewDidStartLoad:_webView];
	}
	else 
	{
		[_webView loadRequest:request];
	}	
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self loadURL:_url];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark Actions

-(void)dismiss:(id)sender
{
	if ([delegate respondsToSelector:@selector(adsdkAdBrowserControllerDidDismiss:)])
	{
		[delegate adsdkAdBrowserControllerDidDismiss:self];
	}
	else 
	{
		[self dismissModalViewControllerAnimated:NO];
	}
}

#pragma mark Web View Delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType == UIWebViewNavigationTypeLinkClicked)
	{
		NSURL *url = [request URL];
		
		if ( [url isDeviceSupported])
		{
			[[UIApplication sharedApplication] openURL:url];
		}
		
		return YES;
	}
	
	if (self.userAgent)
	{
		if ([request isKindOfClass:[NSMutableURLRequest class]])
		{
			[(NSMutableURLRequest *)request addValue:self.userAgent  forHTTPHeaderField:@"User-Agent"];
		}
	}
	
	return YES;
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	return;
}


#pragma mark Manual URL Loading for custom user agent
- (NSMutableData *)receivedData
{
	if (!receivedData)
	{
		receivedData = [[NSMutableData alloc] init];
	}
	
	return receivedData;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
	self.url = request.URL;
	
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.mimeType = response.MIMEType;
	self.textEncodingName = response.textEncodingName;
	
	[self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	receivedData = nil;
	
	[self webView:_webView didFailLoadWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *scheme = [_url scheme];
	NSString *host = [_url host];
	NSString *path = [[_url path] stringByDeletingLastPathComponent];
	
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@/", scheme, host, path]];
	
	[_webView loadData:receivedData MIMEType:self.mimeType textEncodingName:textEncodingName baseURL:baseURL];
	[self webViewDidFinishLoad:_webView];
}

@end
