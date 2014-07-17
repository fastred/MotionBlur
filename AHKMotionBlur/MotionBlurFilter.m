//
//  MotionBlurFilter.m
//  AHKMotionBlur
//
//  Created by Arkadiusz on 17-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import "MotionBlurFilter.h"

CGRect regionOf(CGRect rect, CIVector *velocity)
{
    return CGRectInset(rect, -abs(velocity.X), -abs(velocity.Y));
}

@implementation MotionBlurFilter

- (CIKernel *)myKernel
{
    // TODO: use dispatch_once
    static CIKernel *kernel;
    if (!kernel) {
        NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"MotionBlurKernelSource" withExtension:@"txt"];
        NSError *error;
        NSString *kernelSource = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];

        if (!kernelSource) {
            NSLog(@"%@", [error localizedDescription]);
        }

        kernel = [CIKernel kernelWithString:kernelSource];
    }

    return kernel;
}

- (CIImage *)outputImage
{
    float r = 20;
    float a = M_PI_2;
    CIVector *velocity = [CIVector vectorWithX:r*cos(a) Y:r*sin(a)];
    CGRect DOD = CGRectInset(self.inputImage.extent, -abs(velocity.X), -abs(velocity.Y));

    return [[self myKernel] applyWithExtent:DOD
                                roiCallback:^CGRect(int index, CGRect rect) {
                                    return regionOf(rect, velocity);
                                } arguments: @[self.inputImage, velocity]];
    
}

@end
