//
//  MotionBlurFilter.h
//  AHKMotionBlur
//
//  Created by Arkadiusz on 17-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import <CoreImage/CoreImage.h>

@interface MotionBlurFilter : CIFilter
@property (strong, nonatomic) CIImage *inputImage;
@property (strong, nonatomic) NSNumber *inputRadius;
@property (strong, nonatomic) NSNumber *inputAngle;
@property (strong, nonatomic) NSNumber *numSamples;
@end
