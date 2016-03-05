//
//  CameraToolbar.m
//  Blocstagram
//
//  Created by Jack Li on 3/4/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "CameraToolbar.h"

@interface CameraToolbar ()

@property (nonatomic) UIButton* leftButton;
@property (nonatomic) UIButton* cameraButton;
@property (nonatomic) UIButton* rightButton;

@property (nonatomic) UIView* whiteView;
@property (nonatomic) UIView* purpleView;

@end

@implementation CameraToolbar

- (instancetype) initWithImageNames:(NSArray *)imageNames {
    self = [super init];
    if (self) {
        self.leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [self.leftButton addTarget:self action:@selector(leftButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.cameraButton addTarget:self action:@selector(cameraButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.rightButton addTarget:self action:@selector(rightButtonPressed:)  forControlEvents:UIControlEventTouchUpInside];
        
        [self.leftButton setImage:[UIImage imageNamed:imageNames.firstObject] forState:UIControlStateNormal];
        [self.rightButton setImage:[UIImage imageNamed:imageNames.lastObject] forState:UIControlStateNormal];
        [self.cameraButton setImage:@"camera" forState:UIControlStateNormal];
        [self.cameraButton setContentEdgeInsets:UIEdgeInsetsMake(10, 10, 15, 10)];
        
        self.whiteView = [UIView new];
        self.whiteView.backgroundColor = [UIColor whiteColor];
        
        self.purpleView = [UIView new];
        self.purpleView.backgroundColor = [UIColor colorWithRed:0.345 green:0.318 blue:0.424 alpha:1]; // #58516C
        
        for (UIView* view in @[self.whiteView, self.purpleView, self.leftButton, self.cameraButton, self.rightButton]) {
            [self addSubview:view];
            view.translatesAutoresizingMaskIntoConstraints = NO;
        }
        
        [self createConstraints];
    }
    return self;
}

- (void) createConstraints {
    NSDictionary* viewDictionary = NSDictionaryOfVariableBindings(_leftButton, _cameraButton, _rightButton, _whiteView, _purpleView);
    
    // 3 buttons have equal widths
    NSArray* allButtonsHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_leftButton][_cameraButton(==_leftButton)][_rightButton(==_leftButton)]|" options:kNilOptions metrics:nil views:viewDictionary];
    
    // left and right buttons are 10 from top; all aligned on bottom
    NSArray* leftButtonVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_leftButton]|" options:kNilOptions metrics:nil views:viewDictionary];
    NSArray* cameraButtonVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_cameraButton]|" options:kNilOptions metrics:nil views:viewDictionary];
    NSArray* rightButtonVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_rightButton]|" options:kNilOptions metrics:nil views:viewDictionary];
    
    // white view goes behind all buttons, 10 pts from top
    NSArray* whiteViewHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_whiteView]|" options:kNilOptions metrics:nil views:viewDictionary];
    NSArray* whiteViewVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_whiteView]|" options:kNilOptions metrics:nil views:viewDictionary];
    
    // purple view is positioned identically to camera button
    NSArray* purpleViewHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_leftButton][_purpleView][_rightButton]|" options:kNilOptions metrics:nil views:viewDictionary];
    NSArray* purpleViewVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_purpleView]|" options:kNilOptions metrics:nil views:viewDictionary];
    
    NSArray* allConstraintsArrays = @[allButtonsHorizontalConstraints, leftButtonVerticalConstraints, cameraButtonVerticalConstraints, rightButtonVerticalConstraints, whiteViewHorizontalConstraints, whiteViewVerticalConstraints, purpleViewHorizontalConstraints, purpleViewVerticalConstraints];
    
    for (NSArray* constraintsArray in allConstraintsArrays) {
        for (NSLayoutConstraint* constraint in constraintsArray) {
            [self addConstraint:constraint];
        }
    }
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    UIBezierPath* maskPath = [UIBezierPath bezierPathWithRoundedRect:self.purpleView.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(10.0, 10.0)];
    CAShapeLayer* maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.purpleView.bounds;
    maskLayer.path = maskPath.CGPath;
    
    self.purpleView.layer.mask = maskLayer;
}

#pragma mark - Button Handlers

- (void) leftButtonPressed:(UIButton*)sender {
    [self.delegate leftButtonPressedOnToolbar:self];
}

- (void) rightButtonPressed:(UIButton*)sender {
    [self.delegate rightButtonPressedOnToolbar:self];
}

- (void) cameraButtonPressed:(UIButton*)sender {
    [self.delegate cameraButtonPressedOnToolbar:self];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
