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

@property (weak, nonatomic) CALayer *blurLayer;
@property (weak, nonatomic) CADisplayLink *displayLink;
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
    objc_setAssociatedObject(self, @selector(displayLink), displayLink, OBJC_ASSOCIATION_ASSIGN);
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

            blurLayer.actions = @{ @"opacity" : [NSNull null] };
            [self.layer addSublayer:blurLayer];
            self.blurLayer = blurLayer;

            // CADisplayLink will run indefinitely, unless `-disableBlur` is called.
            CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
            [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            self.displayLink = displayLink;

            CGImageRelease(blurredImgRef);

            if (completionBlock) {
                completionBlock();
            }
        });
    });
}

- (void)disableBlur
{
    [self.displayLink invalidate];
    [self.blurLayer removeFromSuperlayer];
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
    CGPoint lastPosition = [self.lastPosition CGPointValue];

    if (self.lastPosition) {
        // TODO: there's an assumption that the animation has constant FPS. The following code should also use a timestamp of the previous frame.

        CGFloat dx = fabs(realPosition.x - lastPosition.x);
        CGFloat dy = fabs(realPosition.y - lastPosition.y);
        CGFloat delta = sqrt(pow(dx, 2) + pow(dy, 2));

        // A rough approximation of a good looking blur. The larger the speed, the larger opacity of the blur layer.
        CGFloat unboundedOpacity = log2(delta) / 5.0f;
        float opacity = (float)fmax(fmin(unboundedOpacity, 1.0), 0.0);
        self.blurLayer.opacity = opacity;
    }

    self.lastPosition = [NSValue valueWithCGPoint:realPosition];
}

@end
