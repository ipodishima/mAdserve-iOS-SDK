//
//  NSURL+AdSdk.m
//

#import "NSURL+AdSdk.h"


@implementation NSURL (AdSdk)

- (BOOL)isDeviceSupported
{
	NSString *scheme = [self scheme];
	NSString *host = [self host];
	
	if ([scheme isEqualToString:@"tel"] || [scheme isEqualToString:@"sms"] || [scheme isEqualToString:@"mailto"])
	{
		return YES;
	}
	
	if ([scheme isEqualToString:@"http"])
	{
		if ([host isEqualToString:@"maps.google.com"])
		{
			return YES;
		}
		
		if ([host isEqualToString:@"www.youtube.com"])
		{
			return YES;
		}
		
		if ([host isEqualToString:@"phobos.apple.com"])
		{
			return YES;
		}
		
		if ([host isEqualToString:@"itunes.apple.com"])
		{
			return YES;
		}
	}
	
	return NO;	
}

@end


@implementation DummyURL

@end
