//
//  UIView+MotionBlur.h
//  AHKMotionBlur
//
//  Created by Arkadiusz on 19-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  A category for adding motion blur effect to the view when it changes its position.
 */
@interface UIView (MotionBlur)

/**
 *  Enables the motion blur effect when the view changes its position.
 *
 *  @param angle           Angle at which the view will change its position.
 *  @param completionBlock Block called after the computation is completed.
 *  @discussion
 *  The way it works internally: blurred snapshot image is set as a new layer's contents, and then this layer is added as a sublayer.
 *  During animations the current position is compared to the previous one and based on that the opacity of the aforementioned layer is adjusted.
 *  @warning
 *  Please note that calling this method is expensive. Taking a snapshot is performed on the main thread, adding a blur on a background thread. Also, it's really slow when run on the iOS Simulator.
 */
- (void)enableBlurWithAngle:(CGFloat)angle completion:(void (^)(void))completionBlock;

/**
 *  Disables the motion blur effect. The category uses a CADisplayLink internally, so please remember to call this method or you'll have a retain cycle.
 */
- (void)disableBlur;

@end

