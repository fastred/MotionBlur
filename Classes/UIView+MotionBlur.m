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
#import "UIView+AHKSnapshot.h"


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

static CGFloat positionDelta(CGPoint previousPosition, CGPoint currentPosition)
{
    const CGFloat dx = fabs(currentPosition.x - previousPosition.x);
    const CGFloat dy = fabs(currentPosition.y - previousPosition.y);
    return sqrt(pow(dx, 2) + pow(dy, 2));
}

static CGFloat opacityFromPositionDelta(CGFloat delta, CFTimeInterval tickDuration)
{
    const NSInteger expectedFPS = 60;
    const CFTimeInterval expectedDuration = 1.0 / expectedFPS;
    const CGFloat normalizedDelta = delta * expectedDuration / tickDuration;

    // A rough approximation of an opacity for a good looking blur. The larger the delta (movement velocity), the larger opacity of the blur layer.
    const CGFloat unboundedOpacity = log2(normalizedDelta) / 5.0f;
    return (CGFloat)fmax(fmin(unboundedOpacity, 1.0), 0.0);
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

#pragma mark - Public

- (void)enableBlurWithAngle:(CGFloat)angle completion:(void (^)(void))completionBlock
{
    // snapshot has to be performed on the main thread
    UIImage *snapshotImage = [self ahk_snapshot];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        CGImageRef blurredImgRef = CGImageCreateByApplyingMotionBlur(snapshotImage, angle);

        dispatch_async(dispatch_get_main_queue(), ^{
            [self disableBlur];

            CALayer *blurLayer = [[CALayer alloc] init];
            blurLayer.contents = (__bridge id)(blurredImgRef);
            blurLayer.opacity = 0;
            blurLayer.frame = [self blurredLayerFrameWithBlurredImage:blurredImgRef];
            blurLayer.actions = @{ NSStringFromSelector(@selector(opacity)) : [NSNull null] };
            CGImageRelease(blurredImgRef);

            [self.layer addSublayer:blurLayer];
            self.ahk_blurLayer = blurLayer;

            [self startDisplayLink];

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


#pragma mark - Private

- (CGRect)blurredLayerFrameWithBlurredImage:(CGImageRef)blurredImgRef
{
    CGFloat scale = [UIScreen mainScreen].scale;
    // Difference in size between the blurred image and the view.
    CGSize difference = CGSizeMake(CGImageGetWidth(blurredImgRef) / scale - CGRectGetWidth(self.frame), CGImageGetHeight(blurredImgRef) / scale - CGRectGetHeight(self.frame));
    CGRect blurLayerFrame = CGRectInset(self.bounds, -difference.width / 2, -difference.height / 2);
    return blurLayerFrame;
}

- (void)startDisplayLink
{
    // WARNING: CADisplayLink will run indefinitely, unless `-disableBlur` is called.

    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    self.ahk_displayLink = displayLink;
}

- (void)tick:(CADisplayLink *)displayLink
{
    const CGPoint currentPosition = ((CALayer *)self.layer.presentationLayer).position;
    const CGPoint previousPosition = [self.ahk_lastPosition CGPointValue];

    if (self.ahk_lastPosition) {
        const CGFloat delta = positionDelta(previousPosition, currentPosition);
        self.ahk_blurLayer.opacity = opacityFromPositionDelta(delta, displayLink.duration);
    }

    self.ahk_lastPosition = [NSValue valueWithCGPoint:currentPosition];
}

@end
