//
//  MotionBlurredView.h
//  AHKMotionBlur
//
//  Created by Arkadiusz on 01-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MotionBlurredLayer : CALayer

- (void)prepareBlurForAngle:(CGFloat)angle;

@end


@interface MotionBlurredView : UIImageView
@end
