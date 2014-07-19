//
//  UIView+MotionBlur.m
//  AHKMotionBlur
//
//  Created by Arkadiusz on 19-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import <objc/runtime.h>

#import "UIView+MotionBlur.h"
#import "MotionBlurFilter.h"

@interface UIView (MotionBlurProperties)
@property (nonatomic, weak) CALayer *blurLayer;
@property (nonatomic, strong) CADisplayLink *displayLink;
// CGPoint boxed in NSValue.
@property (nonatomic) NSValue *lastPosition;
@end

@implementation UIView (MotionBlurProperties)

@dynamic blurLayer;
@dynamic displayLink;
@dynamic lastPosition;

- (void)setBlurLayer:(CALayer *)blurLayer
{
    objc_setAssociatedObject(self, @selector(blurLayer), blurLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CALayer *)blurLayer
{
    return objc_getAssociatedObject(self, @selector(blurLayer));
}

- (void)setDisplayLink:(CADisplayLink *)displayLink
{
    objc_setAssociatedObject(self, @selector(displayLink), displayLink, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CADisplayLink *)displayLink
{
    return objc_getAssociatedObject(self, @selector(displayLink));
}

- (void)setLastPosition:(NSValue *)lastPosition
{
    objc_setAssociatedObject(self, @selector(lastPosition), lastPosition, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSValue *)lastPosition
{
    return objc_getAssociatedObject(self, @selector(lastPosition));
}

@end



@implementation UIView (MotionBlur)

- (void)prepareBlurForAngle:(CGFloat)angle completion:(void (^)(void))completionBlock
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
    CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
    CGContextFillRect(graphicsContext, self.bounds);

    // good explanation of differences between drawViewHierarchyInRect:afterScreenUpdates: and renderInContext: https://github.com/radi/LiveFrost/issues/10#issuecomment-28959525
    [self.layer renderInContext:graphicsContext];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CIContext *context = [CIContext contextWithOptions:@{ kCIContextPriorityRequestLow : @YES }];
        CIImage *inputImage = [CIImage imageWithCGImage:snapshotImage.CGImage];

        MotionBlurFilter *motionBlurFilter = [[MotionBlurFilter alloc] init];
        [motionBlurFilter setDefaults];
        motionBlurFilter.inputAngle = @(angle);
        motionBlurFilter.inputImage = inputImage;

        CIImage *outputImage = [motionBlurFilter valueForKey:@"outputImage"];

        // back to UIImage
        CGImageRef blurredImgRef = [context createCGImage:outputImage fromRect:outputImage.extent] ;
        UIImage *blurredImage = [[UIImage alloc] initWithCGImage:blurredImgRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.blurLayer removeFromSuperlayer];

            CALayer *blurLayer = [[CALayer alloc] init];
            blurLayer.contents = (__bridge id)(blurredImage.CGImage);
            blurLayer.opaque = NO;
            blurLayer.opacity = 0.0f;
            blurLayer.backgroundColor = [UIColor clearColor].CGColor;

            CGSize difference = CGSizeMake(blurredImage.size.width - self.frame.size.width,
                                           blurredImage.size.height - self.frame.size.height);
            CGRect frame = CGRectZero;
            frame.origin = CGPointMake(-difference.width / 2, -difference.height / 2);
            frame.size = CGSizeMake(self.bounds.size.width + difference.width,
                                    self.bounds.size.height + difference.height);
            blurLayer.frame = frame;
            blurLayer.actions = @{
                                  @"opacity" : [NSNull null]
                                  };
            [self.layer addSublayer:blurLayer];

            self.blurLayer = blurLayer;
            self.lastPosition = [NSValue valueWithCGPoint:CGPointMake(FLT_MAX, FLT_MAX)];

            if (completionBlock) {
                completionBlock();
            }

            [self.displayLink invalidate];
            // CADisplayLink will run indefinitely, unless `-disableBlur` is called.
            self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
            [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        });
    });
}

- (void)disableBlur
{
    [self.displayLink invalidate];

    [self.blurLayer removeFromSuperlayer];
}

- (void)tick:(CADisplayLink *)displayLink
{
    CGPoint realPosition = ((CALayer *)self.layer.presentationLayer).position;
    CGPoint lastPosition = [self.lastPosition CGPointValue];

    // check if last position isn't "undefined", where undefined is set to FLT_MAX (it's kind of a hack)
    if (lastPosition.x != FLT_MAX) {
        CGFloat dx = abs(lastPosition.x - realPosition.x);
        CGFloat dy = abs(lastPosition.y - realPosition.y);
        CGFloat delta = sqrt(pow(dx, 2) + pow(dy, 2));

        // rough approximation of a good looking blur
        CGFloat unboundedOpacity = log2(delta) / 5.0f;
        CGFloat opacity = fmax(fmin(unboundedOpacity, 1.0), 0.0);
        self.blurLayer.opacity = opacity;
    }

    self.lastPosition = [NSValue valueWithCGPoint:realPosition];
}

@end