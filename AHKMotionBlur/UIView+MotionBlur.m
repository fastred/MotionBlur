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

static CGFloat const kUndefinedCoordinateValue = FLT_MAX;


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

- (void)enableBlurWithAngle:(CGFloat)angle completion:(void (^)(void))completionBlock
{
    // snapshot has to be performed on the main thread
    UIImage *snapshotImage = [self layerSnapshot];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CIContext *context = [CIContext contextWithOptions:@{ kCIContextPriorityRequestLow : @YES }];
        CIImage *inputImage = [CIImage imageWithCGImage:snapshotImage.CGImage];

        MotionBlurFilter *motionBlurFilter = [[MotionBlurFilter alloc] init];
        [motionBlurFilter setDefaults];
        motionBlurFilter.inputAngle = @(angle);
        motionBlurFilter.inputImage = inputImage;

        CIImage *outputImage = [motionBlurFilter valueForKey:@"outputImage"];
        CGImageRef blurredImgRef = [context createCGImage:outputImage fromRect:outputImage.extent] ;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.blurLayer removeFromSuperlayer];

            CALayer *blurLayer = [[CALayer alloc] init];
            blurLayer.contents = (__bridge id)(blurredImgRef);
            blurLayer.opaque = NO;
            blurLayer.opacity = 0.0f;
            blurLayer.backgroundColor = [UIColor clearColor].CGColor;

            CGFloat scale = [UIScreen mainScreen].scale;
            // Difference in size between the blurred image and the view.
            // The blurred image is larger, because the blur crosses the edges.
            CGSize difference = CGSizeMake(CGImageGetWidth(blurredImgRef) / scale - self.frame.size.width,
                                           CGImageGetHeight(blurredImgRef) / scale - self.frame.size.height);
            CGRect frame = CGRectZero;
            frame.origin = CGPointMake(-difference.width / 2, -difference.height / 2);
            frame.size = CGSizeMake(self.bounds.size.width + difference.width,
                                    self.bounds.size.height + difference.height);
            blurLayer.frame = frame;

            blurLayer.actions = @{ @"opacity" : [NSNull null] };
            [self.layer addSublayer:blurLayer];
            self.blurLayer = blurLayer;

            self.lastPosition = [NSValue valueWithCGPoint:CGPointMake(kUndefinedCoordinateValue, kUndefinedCoordinateValue)];

            [self.displayLink invalidate];
            // CADisplayLink will run indefinitely, unless `-disableBlur` is called.
            self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
            [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

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

    if (lastPosition.x != kUndefinedCoordinateValue) {
        CGFloat dx = abs(realPosition.x - lastPosition.x);
        CGFloat dy = abs(realPosition.y - lastPosition.y);
        CGFloat delta = sqrt(pow(dx, 2) + pow(dy, 2));

        // A rough approximation of a good looking blur. The larger the speed, the larger opacity of the blur layer.
        CGFloat unboundedOpacity = log2(delta) / 5.0f;
        CGFloat opacity = fmax(fmin(unboundedOpacity, 1.0), 0.0);
        self.blurLayer.opacity = opacity;
    }

    self.lastPosition = [NSValue valueWithCGPoint:realPosition];
}

@end