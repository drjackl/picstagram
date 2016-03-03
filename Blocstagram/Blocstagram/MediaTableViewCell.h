//
//  MediaTableViewCell.h
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Media, MediaTableViewCell; // declare self for below protocol

// add a delegate method to Cell which will inform VC when user taps on image
@protocol MediaTableViewCellDelegate <NSObject>

- (void) cell:(MediaTableViewCell*)cell didTapImageView:(UIImageView*)imageView;

// for sharing
- (void) cell:(MediaTableViewCell*)cell didLongPressImageView:(UIImageView*)imageView;

@end


@interface MediaTableViewCell : UITableViewCell

@property (nonatomic) Media* mediaItem; // every cell associated with single item

@property (nonatomic, weak) id <MediaTableViewCellDelegate> delegate;

// like static variables declared earlier, but in .h so all classes may use
+ (CGFloat) heightForMediaItem:(Media*)mediaItem width:(CGFloat)width;

@end
