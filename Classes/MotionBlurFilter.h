//
//  MotionBlurFilter.h
//  AHKMotionBlur
//
//  Created by Arkadiusz on 17-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import <CoreImage/CoreImage.h>

@interface MotionBlurFilter : CIFilter
@property (nonatomic, strong) CIImage *inputImage;
@property (nonatomic, strong) NSNumber *inputRadius;
@property (nonatomic, strong) NSNumber *inputAngle;
@property (nonatomic, strong) NSNumber *numSamples;
@end
