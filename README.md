# MotionBlur

`MotionBlur` allows you to add motion blur effect to your animations (currently only position's change). See the [accompanying blog post](http://holko.pl/2014/07/21/motion-blur/) to learn how it's implemented.

![Demo GIF](https://raw.githubusercontent.com/fastred/MotionBlur/master/demo.gif)

*Note how the text and icons on the menu get blurred when it slides in and out.*

## Usage

First, import it with:

```obj-c
#import "UIView+MotionBlur.h"
```

then use it with:

```obj-c
[yourView enableBlurWithAngle:M_PI_2 completion:^{
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.3
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{

        CGRect f = yourView.frame;
        f.origin = CGPointMake(0, 300);
        yourView.frame = f;
    } completion:^(BOOL finished) {
        [yourView disableBlur];
    }];
}];
```

Snapshot and blur are computed before the animation, that's why the API is asynchronous. You should also see the example project and read comments in the header file: `Classes/UIView+MotionBlur.h`.

## Demo

To run the example project; clone the repo and open `Example/MotionBlur.xcodeproj`.

## Requirements

 * iOS 8 and above

## Installation
MotionBlur is available through CocoaPods. To install it, simply add the following line to your Podfile:

    pod "MotionBlur"

## Author

Arkadiusz Holko:

* [Blog](http://holko.pl/)
* [@arekholko on Twitter](https://twitter.com/arekholko)