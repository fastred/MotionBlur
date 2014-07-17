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

// strong, because we'll be deactivating it, so view will stop referencing it
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *motionViewTopHiddenConstraint;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // hide initially
    self.motionViewTopHiddenConstraint.priority = 1000;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [((MotionBlurredLayer *)self.motionBlurredView.layer) prepareBlur];
}

- (IBAction)move:(UIButton *)sender
{
    self.motionViewTopHiddenConstraint.active = !self.motionViewTopHiddenConstraint.active;

    BOOL hiding = self.motionViewTopHiddenConstraint.active;

    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:hiding ? 0.0 : 0.6
                        options:0
                     animations:^{

                         [self.motionBlurredView.superview layoutIfNeeded];

    } completion:^(BOOL finished) {

    }];
//    [UIView animateWithDuration:0.5 delay:0 options:0 animations:^{
//    } completion:nil];
}

@end
