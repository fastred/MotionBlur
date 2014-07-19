//
//  UIView+MotionBlur.h
//  AHKMotionBlur
//
//  Created by Arkadiusz on 19-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView (MotionBlur)

- (void)prepareBlurForAngle:(CGFloat)angle completion:(void (^)(void))completionBlock;
- (void)disableBlur;

@end

