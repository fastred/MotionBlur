//
//  MotionBlurFilter.h
//  AHKMotionBlur
//
//  Created by Arkadiusz on 17-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import <CoreImage/CoreImage.h>

@interface MotionBlurFilter : CIFilter
@property (retain, nonatomic) CIImage *inputImage;
@property (copy, nonatomic) NSNumber *inputRadius;
@property (copy, nonatomic) NSNumber *inputAngle;
@end
