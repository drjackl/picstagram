//
//  LikeButton.h
//  Blocstagram
//
//  Created by Jack Li on 3/3/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

// four possible states
typedef NS_ENUM(NSInteger, LikeState) {
    LikeStateNotLiked = 0,
    LikeStateLiking = 1,
    LikeStateLiked = 2,
    LikeStateUnliking = 3
};

@interface LikeButton : UIButton

@property (nonatomic) LikeState likeButtonState; // expose a property

@end
