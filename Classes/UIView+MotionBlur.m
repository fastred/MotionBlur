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


static CGImageRef CGImageCreateByApplyingMotionBlur(UIImage *snapshotImage, CGFloat angle)
{
    CIContext *context = [CIContext contextWithOptions:@{ kCIContextPriorityRequestLow : @YES }];
    CIImage *inputImage = [CIImage imageWithCGImage:snapshotImage.CGImage];

    MotionBlurFilter *motionBlurFilter = [[MotionBlurFilter alloc] init];
    [motionBlurFilter setDefaults];
    motionBlurFilter.inputAngle = @(angle);
    motionBlurFilter.inputImage = inputImage;

    CIImage *outputImage = motionBlurFilter.outputImage;
    CGImageRef blurredImgRef = [context createCGImage:outputImage fromRect:outputImage.extent] ;
    return blurredImgRef;
}


@interface UIView (MotionBlurProperties)

@property (nonatomic, weak) CALayer *ahk_blurLayer;
@property (nonatomic, weak) CADisplayLink *ahk_displayLink;
@property (nonatomic, strong) NSValue *ahk_lastPosition; // CGPoint boxed in NSValue.

@end


@implementation UIView (MotionBlurProperties)

@dynamic ahk_blurLayer;
@dynamic ahk_displayLink;
@dynamic ahk_lastPosition;

- (void)setAhk_blurLayer:(CALayer *)ahk_blurLayer
{
    objc_setAssociatedObject(self, @selector(ahk_blurLayer), ahk_blurLayer, OBJC_ASSOCIATION_ASSIGN);
}

- (CALayer *)ahk_blurLayer
{
    return objc_getAssociatedObject(self, @selector(ahk_blurLayer));
}

- (void)setAhk_displayLink:(CADisplayLink *)ahk_displayLink
{
    objc_setAssociatedObject(self, @selector(ahk_displayLink), ahk_displayLink, OBJC_ASSOCIATION_ASSIGN);
}

- (CADisplayLink *)ahk_displayLink
{
    return objc_getAssociatedObject(self, @selector(ahk_displayLink));
}

- (void)setAhk_lastPosition:(NSValue *)ahk_lastPosition
{
    objc_setAssociatedObject(self, @selector(ahk_lastPosition), ahk_lastPosition, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSValue *)ahk_lastPosition
{
    return objc_getAssociatedObject(self, @selector(ahk_lastPosition));
}

@end


@implementation UIView (MotionBlur)

- (void)enableBlurWithAngle:(CGFloat)angle completion:(void (^)(void))completionBlock
{
    // snapshot has to be performed on the main thread
    UIImage *snapshotImage = [self layerSnapshot];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        CGImageRef blurredImgRef = CGImageCreateByApplyingMotionBlur(snapshotImage, angle);

        dispatch_async(dispatch_get_main_queue(), ^{
            [self disableBlur];

            CALayer *blurLayer = [[CALayer alloc] init];
            blurLayer.contents = (__bridge id)(blurredImgRef);
            blurLayer.opacity = 0.0f;

            CGFloat scale = [UIScreen mainScreen].scale;
            // Difference in size between the blurred image and the view.
            CGSize difference = CGSizeMake(CGImageGetWidth(blurredImgRef) / scale - CGRectGetWidth(self.frame), CGImageGetHeight(blurredImgRef) / scale - CGRectGetHeight(self.frame));
            blurLayer.frame = CGRectInset(self.bounds, -difference.width / 2, -difference.height / 2);

            blurLayer.actions = @{ NSStringFromSelector(@selector(opacity)) : [NSNull null] };
            [self.layer addSublayer:blurLayer];
            self.ahk_blurLayer = blurLayer;

            // CADisplayLink will run indefinitely, unless `-disableBlur` is called.
            CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
            [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            self.ahk_displayLink = displayLink;

            CGImageRelease(blurredImgRef);

            if (completionBlock) {
                completionBlock();
            }
        });
    });
}

- (void)disableBlur
{
    [self.ahk_displayLink invalidate];
    [self.ahk_blurLayer removeFromSuperlayer];
    self.ahk_lastPosition = nil;
}

- (UIImage *)layerSnapshot
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

- (void)tick:(CADisplayLink *)displayLink
{
    CGPoint realPosition = ((CALayer *)self.layer.presentationLayer).position;
    CGPoint lastPosition = [self.ahk_lastPosition CGPointValue];

    if (self.ahk_lastPosition) {
        // TODO: there's an assumption that the animation has constant FPS. The following code should also use a timestamp of the previous frame.

        CGFloat dx = fabs(realPosition.x - lastPosition.x);
        CGFloat dy = fabs(realPosition.y - lastPosition.y);
        CGFloat delta = sqrt(pow(dx, 2) + pow(dy, 2));

        // A rough approximation of a good looking blur. The larger the speed, the larger opacity of the blur layer.
        CGFloat unboundedOpacity = log2(delta) / 5.0f;
        float opacity = (float)fmax(fmin(unboundedOpacity, 1.0), 0.0);
        self.ahk_blurLayer.opacity = opacity;
    }

    self.ahk_lastPosition = [NSValue valueWithCGPoint:realPosition];
}

@end
