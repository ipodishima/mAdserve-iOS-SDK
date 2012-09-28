//
//  UIButton+AdSdk.m
//

#import <objc/runtime.h>
#import "UIButton+AdSdk.h"

static char const * const ObjectTagKey = "ObjectTag";

@implementation UIButton (AdSdk)

@dynamic objectTag;

- (id)objectTag {
    return objc_getAssociatedObject(self, ObjectTagKey);
}

- (void)setObjectTag:(id)newObjectTag {
    objc_setAssociatedObject(self, ObjectTagKey, newObjectTag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
