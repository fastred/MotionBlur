//
//  MotionBlurFilter.m
//  AHKMotionBlur
//
//  Created by Arkadiusz on 17-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import "MotionBlurFilter.h"


static NSString * const kKernelSource = @"kernel vec4 motionBlur (sampler image, vec2 velocity) { \
const int NUM_SAMPLES = 3; \
\
vec4 s = vec4(0.0); \
vec2 dc = destCoord(), offset = -velocity; \
\
for (int i=0; i < (NUM_SAMPLES * 2 + 1); i++) { \
    s += sample (image, samplerTransform (image, dc + offset)); \
    offset += velocity / float(NUM_SAMPLES); \
} \
\
return s / float((NUM_SAMPLES * 2 + 1)); \
}";

CGRect regionOf(CGRect rect, CIVector *velocity)
{
    return CGRectInset(rect, -abs(velocity.X), -abs(velocity.Y));
}

@implementation MotionBlurFilter

- (CIKernel *)myKernel
{
    static CIKernel *kernel;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kernel = [CIKernel kernelWithString:kKernelSource];
    });

    return kernel;
}

- (void)setDefaults
{
    [super setDefaults];

    self.inputRadius = @(40);
    self.inputAngle = @(M_PI_2);
}

- (CIImage *)outputImage
{
    float r = self.inputRadius.floatValue;
    float a = self.inputAngle.floatValue;
    CIVector *velocity = [CIVector vectorWithX:r*cos(a) Y:r*sin(a)];
    CGRect DOD = CGRectInset(self.inputImage.extent, -abs(velocity.X), -abs(velocity.Y));

    return [[self myKernel] applyWithExtent:DOD
                                roiCallback:^CGRect(int index, CGRect rect) {
                                    return regionOf(rect, velocity);
                                } arguments: @[self.inputImage, velocity]];
    
}

@end
