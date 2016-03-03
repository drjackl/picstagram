//
//  LikeButton.m
//  Blocstagram
//
//  Created by Jack Li on 3/3/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "LikeButton.h"
#import "CircleSpinnerView.h"

// define image names
#define kLikedStateImage @"heart-full"
#define kUnlikedStateImage @"heart-empty"

@interface LikeButton () // extension for spinnerView property

@property (nonatomic) CircleSpinnerView* spinnerView;

@end

@implementation LikeButton

// in initializer, create spinner view and setup button
- (instancetype) init {
    self = [super init];
    
    if (self) {
        self.spinnerView = [[CircleSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [self addSubview:self.spinnerView];
        
        // self.imageView is part of UIButtons
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        // provides buffer between edge of button and content
        self.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        
        // specifies alignment of button's content, default is centered
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
        
        self.likeButtonState = LikeStateNotLiked;
    }
    
    return self;
}

// spinner view's frame should be updated whenever button's frame changes
- (void) layoutSubviews {
    [super layoutSubviews];
    self.spinnerView.frame = self.imageView.frame;
}

// override setter to update button's appearance based on state
- (void) setLikeButtonState:(LikeState)likeButtonState {
    _likeButtonState = likeState;
    
    NSString* imageName;
    
    switch (_likeButtonState) {
        case LikeStateLiked:
        case LikeStateUnliking:
            imageName = kLikedStateImage;
            break;
            
        case LikeStateNotLiked:
        case LikeStateLiking:
            imageName = kUnlikedStateImage;

//        default: // no defaults
//            break;
    }
    
    switch (_likeButtonState) {
        case LikeStateLiking:
        case LikeStateUnliking:
            self.spinnerView.hidden = NO;
            self.userInteractionEnabled = NO;
            break;

        case LikeStateLiked:
        case LikeStateNotLiked:
            self.spinnerView.hidden = YES;
            self.userInteractionEnabled = YES;
    }
    
    [self setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
