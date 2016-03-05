//
//  MediaTableViewCell.h
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

// declare self for below protocol
@class Media, MediaTableViewCell, ComposeCommentView;

// add a delegate method to Cell which will inform VC when user taps on image
@protocol MediaTableViewCellDelegate <NSObject>

- (void) cell:(MediaTableViewCell*)cell didTapImageView:(UIImageView*)imageView;

// for sharing
- (void) cell:(MediaTableViewCell*)cell didLongPressImageView:(UIImageView*)imageView;

// for retry download image
- (void) cell:(MediaTableViewCell*)cell didTwoFingerTapImageView:(UIImageView*)imageView;

// for adding like button to table cell
- (void) cellDidPressLikeButton:(MediaTableViewCell*)cell;

// compose view delegate methods
- (void) cellWillStartComposingComment:(MediaTableViewCell*)cell;
- (void) cell:(MediaTableViewCell*)cell didComposeComment:(NSString*)comment;

@end


@interface MediaTableViewCell : UITableViewCell

@property (nonatomic) Media* mediaItem; // every cell associated with single item

@property (nonatomic, weak) id <MediaTableViewCellDelegate> delegate;

// for compose view
@property (nonatomic, readonly) ComposeCommentView* commentView;

// like static variables declared earlier, but in .h so all classes may use
+ (CGFloat) heightForMediaItem:(Media*)mediaItem width:(CGFloat)width;

// compose view method
- (void) stopComposingComment;

@end
