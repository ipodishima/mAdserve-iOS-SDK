//
//  UIBarButtonItem+AdSdk.m
//

#import <objc/runtime.h>
#import "UIBarButtonItem+AdSdk.h"

static char const * const ObjectTagKey = "ObjectTag";

@implementation UIBarButtonItem (AdSdk)

@dynamic objectTag;

- (id)objectTag {
    return objc_getAssociatedObject(self, ObjectTagKey);
}

- (void)setObjectTag:(id)newObjectTag {
    objc_setAssociatedObject(self, ObjectTagKey, newObjectTag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
