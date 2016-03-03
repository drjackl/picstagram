//
//  CircleViewSpinner.m
//  Blocstagram
//
//  Created by Jack Li on 3/3/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "CircleSpinnerView.h"

@interface CircleSpinnerView ()

@property (nonatomic) CAShapeLayer* circleLayer;

@end // comment was green here

@implementation CircleSpinnerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

// create circleLayer by overriding getter, create on first call (black at first)
- (CAShapeLayer*) circleLayer {
    if (!_circleLayer) {
        // arc is entire circle in this case
        CGPoint arcCenter = CGPointMake(self.radius + self.strokeThickness/2 + 5,
                                        self.radius + self.strokeThickness/2 + 5);
        // spinning circle will fit inside this rect
        CGRect rect = CGRectMake(0, 0, arcCenter.x*2, arcCenter.y*2);
        
        // for angles, 0 is east, pi/2 is south, pi is west, 3pi/2 is north
        UIBezierPath* smoothPath = [UIBezierPath bezierPathWithArcCenter:arcCenter
                                                                  radius:self.radius
                                                              startAngle:M_PI*3/2
                                                                endAngle:M_PI/2 + M_PI*5
                                                               clockwise:NO];
        
        // layer is made from bezier path
        // also, core animation uses CGColorRef not UIColor
        _circleLayer = [CAShapeLayer layer];
        _circleLayer.contentsScale = [[UIScreen mainScreen] scale]; // 1.0 regular, 2.0 retina displays
        _circleLayer.frame = rect;
        _circleLayer.fillColor = [UIColor clearColor].CGColor; // transparent so can see heart
        _circleLayer.strokeColor = self.strokeColor.CGColor; // want same defined color
        _circleLayer.lineWidth = self.strokeThickness;
        _circleLayer.lineCap = kCALineCapRound;
        _circleLayer.lineJoin = kCALineJoinBevel;
        _circleLayer.path = smoothPath.CGPath;
        
        // angle-mask is like a clock from clear noon to opaque midnight
        CALayer* maskLayer = [CALayer layer];
        maskLayer.contents = (id)[UIImage imageNamed:@"angle-mask"].CGImage;
        maskLayer.frame = _circleLayer.bounds;
        _circleLayer.mask = maskLayer;
        
        // now will animate mask in circular motion
        CFTimeInterval animationDuration = 1; // seconds
        CAMediaTimingFunction* linearCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]; // linear means constant
        
        // animation repeated infinite
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        animation.fromValue = @0;
        animation.toValue = @(M_PI*2);
        animation.duration = animationDuration;
        animation.timingFunction = linearCurve;
        animation.removedOnCompletion = NO;
        animation.repeatCount = INFINITY;
        animation.fillMode = kCAFillModeForwards; // specifies what happens when animation is complete
        animation.autoreverses = NO;
        [_circleLayer.mask addAnimation:animation forKey:@"rotate"];
        
        // now that mask animated, just animate the line that draws circle itself
        CAAnimationGroup* animationGroup = [CAAnimationGroup animation];
        animationGroup.duration = animationDuration;
        animationGroup.repeatCount = INFINITY;
        animationGroup.removedOnCompletion = NO;
        animationGroup.timingFunction = linearCurve;
        
        CABasicAnimation* strokeStartAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
        strokeStartAnimation.fromValue = @0.015;
        strokeStartAnimation.toValue = @0.515;
        
        CABasicAnimation* strokeEndAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        strokeEndAnimation.fromValue = @0.485;
        strokeEndAnimation.toValue = @0.985;
        
        // CAAnimationGroup groups multiple animations and runs them concurrently
        animationGroup.animations = @[strokeStartAnimation, strokeEndAnimation];
        [_circleLayer addAnimation:animationGroup forKey:@"progress"];
    }
    return _circleLayer;
}

// ensures circle animation positioned properly
- (void) layoutAnimatedLayer {
    [self.layer addSublayer:self.circleLayer];
    
    // puts circle layer in center of view
    self.circleLayer.position = CGPointMake(CGRectGetMidX(self.bounds),
                                            CGRectGetMidY(self.bounds));
}


// when subview added, it can react to this in willMoveToSuperview:, so implement method to ensure position is accurate
- (void) willMoveToSuperview:(UIView*)newSuperview {
    if (newSuperview != nil) {
        [self layoutAnimatedLayer];
    } else {
        [self.circleLayer removeFromSuperlayer];
        self.circleLayer = nil;
    }
}

// update position of layer if frame changes
- (void) setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (self.superview != nil) {
        [self layoutAnimatedLayer];
    }
}

// changing radius will affect position too, so override setter
- (void) setRadius:(CGFloat)radius {
    _radius = radius;
    
    [_circleLayer removeFromSuperlayer];
    _circleLayer = nil;
    
    [self layoutAnimatedLayer];
}

// should also inform self.circleLayer if stroke width or color changes
- (void)setStrokeColor:(UIColor*)strokeColor {
    _strokeColor = strokeColor;
    _circleLayer.strokeColor = strokeColor.CGColor;
}

// see above (stroke color) method
- (void) setStrokeThickness:(CGFloat)strokeThickness {
    _strokeThickness = strokeThickness;
    _circleLayer.lineWidth = _strokeThickness;
}

// set default values in initializer and provide hint about size
- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.strokeThickness = 1;
        self.radius = 12;
        self.strokeColor = [UIColor purpleColor];
    }
    return self;
}

// also override
- (CGSize) sizeThatFits:(CGSize)size {
    return CGSizeMake(2*(self.radius+self.strokeThickness/2+5),
                      2*(self.radius+self.strokeThickness/2+5));
}

// if i hit return twice after the boilerplate, it's black

// this text was black, then turned green quickly

// comment not green, but green after reset xcode

@end
