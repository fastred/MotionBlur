//
//  MotionBlurFilter.m
//  AHKMotionBlur
//
//  Created by Arkadiusz on 17-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import "MotionBlurFilter.h"

// The source should be included in a separate file, but it would be harder to distribute, so I put it in a string.
static NSString * const kKernelSource = @"kernel vec4 motionBlur(sampler image, vec2 velocity, float numSamplesInput) {\
\
    int numSamples = int(floor(numSamplesInput));\
    vec4 sum = vec4(0.0), avg = vec4(0.0);\
    vec2 dc = destCoord(), offset = -velocity;\
\
    for (int i=0; i < (numSamples * 2 + 1); i++) {\
        sum += sample (image, samplerTransform (image, dc + offset));\
        offset += velocity / float(numSamples);\
    }\
\
    avg = sum / float((numSamples * 2 + 1));\
    return avg;\
}\
";

CG_INLINE CGRect regionOf(CGRect rect, CIVector *velocity)
{
    return CGRectInset(rect, -fabs(velocity.X), -fabs(velocity.Y));
}

@implementation MotionBlurFilter

- (CIKernel *)myKernel
{
    static CIKernel *kernel = nil;

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
    self.numSamples = @(5);
}

- (CIImage *)outputImage
{
    float r = self.inputRadius.floatValue;
    float a = self.inputAngle.floatValue;
    CIVector *velocity = [CIVector vectorWithX:r*cos(a) Y:r*sin(a)];
    CGRect dod = regionOf(self.inputImage.extent, velocity);

    return [[self myKernel] applyWithExtent:dod
                                roiCallback:^CGRect(int index, CGRect rect) {
                                    return regionOf(rect, velocity);
                                } arguments: @[self.inputImage, velocity, self.numSamples]];
}

@end
