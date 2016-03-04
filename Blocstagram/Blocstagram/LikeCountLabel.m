//
//  LikeCountLabel.m
//  Blocstagram
//
//  Created by Jack Li on 3/3/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "LikeCountLabel.h"

@implementation LikeCountLabel

- (instancetype) initWithCount:(int)count {
    self = [super init];
    if (self) {
        self.likeCount = count;
    }
    return self;
}

- (void) setLikeCount:(int)likeCount {
    _likeCount = likeCount;
    
    self.text = [NSString stringWithFormat:@"%d", _likeCount];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
