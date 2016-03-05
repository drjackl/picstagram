//
//  ComposeCommentView.h
//  Blocstagram
//
//  Created by Jack Li on 3/3/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ComposeCommentView;

@protocol ComposeCommentViewDelegate <NSObject>

- (void) commentViewDidPressCommentButton:(ComposeCommentView*)sender;
- (void) commentView:(ComposeCommentView*)sender textDidChange:(NSString*)text;
- (void) commentViewWillStartEditing:(ComposeCommentView*)sender;

@end


@interface ComposeCommentView : UIView

@property (nonatomic, weak) NSObject<ComposeCommentViewDelegate>* delegate;

@property (nonatomic) BOOL isWritingComment; // self-explanatory

// text of comment and can be set by external controller
@property (nonatomic) NSString* text;

// ends composition and dismisses keyboard
- (void) stopComposingComment;

@end
