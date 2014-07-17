//
//  MotionBlurredView.m
//  AHKMotionBlur
//
//  Created by Arkadiusz on 01-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import "MotionBlurredView.h"

@interface MotionBlurredView()

@property (weak, nonatomic) UIImageView *blurImageView;

@end

@implementation MotionBlurredView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)enableMotionBlur
{
    CGFloat insetX = 50;
    CGFloat insetY = 50;
    CGRect snapshotFrame = CGRectInset(self.bounds, -insetX, -insetY);

    UIGraphicsBeginImageContextWithOptions(snapshotFrame.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *transparent = [UIColor colorWithRed:0.886 green:0.847 blue:0.812 alpha:0];
    CGContextSetFillColorWithColor(context, transparent.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, CGRectGetWidth(snapshotFrame), CGRectGetHeight(snapshotFrame)));
    [self drawViewHierarchyInRect:CGRectMake(insetX, insetY, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)) afterScreenUpdates:YES];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

//    GPUImageMotionBlurFilter *motionBlurFilter = [[GPUImageMotionBlurFilter alloc] init];
//    motionBlurFilter.blurAngle = 90;
//    motionBlurFilter.blurSize = 20.0f;
//
//    UIImage *blurredImage = [motionBlurFilter imageByFilteringImage:snapshotImage];
//
//    NSData *pngData = UIImagePNGRepresentation(blurredImage);
//
//    NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
//                                                               inDomains:NSUserDomainMask] lastObject];
//    NSString *path = [documents.path
//                      stringByAppendingPathComponent:[NSString stringWithFormat:@"blurredImage%ld.png", (long)[[NSDate date] timeIntervalSince1970]]];
//    [pngData writeToFile:path atomically:YES];

//    if (!self.blurImageView) {
//        UIImageView *imageView = [[UIImageView alloc] initWithImage:blurredImage];
//        imageView.backgroundColor = [UIColor clearColor];
//        imageView.opaque = NO;
//        CGRect f = imageView.frame;
//        f.origin = CGPointMake(-insetX, -insetY);
//        imageView.frame = f;
//
//        [self addSubview:imageView];
//
//        self.blurImageView = imageView;
//    }
}

@end
