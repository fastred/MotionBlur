//
//  UIView+AHKSnapshot.m
//  MotionBlur
//
//  Created by Arkadiusz on 04-04-15.
//  Copyright (c) 2015 Arkadiusz Holko. All rights reserved.
//

#import "UIView+AHKSnapshot.h"


@implementation UIView (AHKSnapshot)

- (UIImage *)ahk_snapshot
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
    CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
    CGContextFillRect(graphicsContext, self.bounds);

    // good explanation of differences between drawViewHierarchyInRect:afterScreenUpdates: and renderInContext: https://github.com/radi/LiveFrost/issues/10#issuecomment-28959525
    [self.layer renderInContext:graphicsContext];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return snapshotImage;
}


@end
