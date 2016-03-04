//
//  LikeCountLabel.h
//  Blocstagram
//
//  Created by Jack Li on 3/3/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LikeCountLabel : UILabel

@property (nonatomic) int likeCount;

- (instancetype) initWithCount:(int)count;

@end
