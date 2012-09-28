//
//  NSBundle+AdSdk.m
//

#import "NSBundle+AdSdk.h"

@implementation NSBundle (AdSdk)

+ (NSBundle*)adSdkLibraryResourcesBundle {
    
    static dispatch_once_t onceToken;
    static NSBundle *adSdkLibraryResourcesBundle = nil;
        
    dispatch_once(&onceToken, ^{
        adSdkLibraryResourcesBundle = [NSBundle bundleWithIdentifier:@"com.adsdk.AdSdk"];
    });
    
    return adSdkLibraryResourcesBundle;
}
@end
