//
//  NSURL+AdSdk.h
//

#import <Foundation/Foundation.h>


@interface NSURL (AdSdk)

- (BOOL)isDeviceSupported;

@end

// this makes the -all_load linker flag unnecessary, -ObjC still needed
@interface DummyURL

@end