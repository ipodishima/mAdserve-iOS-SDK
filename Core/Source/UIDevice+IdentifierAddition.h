//
//  UIDevice(Identifier).h
//  UIDeviceAddition
//

#import <UIKit/UIKit.h>

@interface UIDevice (IdentifierAddition)

- (NSString *) uniqueDeviceIdentifier;
- (NSString *) uniqueGlobalDeviceIdentifier;
- (NSString *) uniqueGlobalDeviceIdentifierSHA1;
+ (NSString *) localWiFiIPAddress;
+ (NSString *) localCellularIPAddress;
+ (NSString *) localSimulatorIPAddress;

@end
