//
//  ViewController.m
//  AHKMotionBlur
//
//  Created by Arkadiusz on 01-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import "ViewController.h"
#import "UIView+MotionBlur.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *motionBlurredView;

// strong, because we'll be deactivating it, so view will stop referencing it
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *motionViewTopHiddenConstraint;

@property (weak, nonatomic) IBOutlet UIButton *toggleButton;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // hide initially
    self.motionViewTopHiddenConstraint.priority = 1000;

    [self.toggleButton setTitle:@"Creating motion blurred layer…" forState:UIControlStateNormal];
    self.toggleButton.enabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    __weak typeof(self)weakSelf = self;
    [self.motionBlurredView prepareBlurForAngle:M_PI_2 completion:^{
        [weakSelf.toggleButton setTitle:@"Toggle" forState:UIControlStateNormal];
        weakSelf.toggleButton.enabled = YES;
    }];
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
}

@end
