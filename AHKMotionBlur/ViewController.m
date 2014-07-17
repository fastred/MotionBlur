//
//  ViewController.m
//  AHKMotionBlur
//
//  Created by Arkadiusz on 01-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import "ViewController.h"
#import "MotionBlurredView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet MotionBlurredView *motionBlurredView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *motionViewTopConstraint;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)move:(UIButton *)sender
{
    [self.motionBlurredView enableMotionBlur];
}

@end
