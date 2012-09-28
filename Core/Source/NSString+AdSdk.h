//
//  NSString+AdSdk.h
//

#import <Foundation/Foundation.h>


@interface NSString (AdSdk)
- (NSString *)stringByUrlEncoding;
- (NSString * )md5;
- (NSString*)sha1;
@end


// this makes the -all_load linker flag unnecessary, -ObjC still needed
@interface DummyString : NSString

@end

