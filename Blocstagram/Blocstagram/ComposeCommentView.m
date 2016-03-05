//
//  ComposeCommentView.m
//  Blocstagram
//
//  Created by Jack Li on 3/3/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "ComposeCommentView.h"

@interface ComposeCommentView () <UITextViewDelegate> // informs of actions

@property (nonatomic) UITextView* textView;
@property (nonatomic) UIButton* button;

@end

@implementation ComposeCommentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // initalization code
        self.textView = [UITextView new];
        self.textView.delegate = self;
        
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.button setAttributedTitle:[self commentAttributedString] forState:UIControlStateNormal];
        [self.button addTarget:self action:@selector(commentButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        // note: self >> self.textView >> self.button (self.button not in self)
        [self addSubview:self.textView];
        [self.textView addSubview:self.button];
    }
    return self;
}

// string for comment button text (COMMENT)
- (NSAttributedString*) commentAttributedString {
    NSString* baseString = NSLocalizedString(@"COMMENT", @"comment button text");
    NSRange range = NSMakeRange(0, baseString.length);
    
    NSMutableAttributedString* commentString = [[NSMutableAttributedString alloc] initWithString:baseString];
    
    [commentString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:10] range:range];
    [commentString addAttribute:NSKernAttributeName value:@1.3 range:range];
    [commentString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1] range:range];
    
    return commentString;
}

// two states - 1. while scrolling, comment button gray on left; 2. while editing, button slides to right and fades to purple
- (void) layoutSubviews {
    [super layoutSubviews];
    
    self.textView.frame = self.bounds;
    
    if (self.isWritingComment) { // user is editing
        self.textView.backgroundColor = [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1]; // #EEEEEE
        self.button.backgroundColor = [UIColor colorWithRed:0.345 green:0.318 blue:0.424 alpha:1]; // #58516C, button purple?
        
        // button on right
        CGFloat buttonX = CGRectGetWidth(self.bounds) - CGRectGetWidth(self.button.frame) - 20;
        self.button.frame = CGRectMake(buttonX, 10, 80, 20);
    } else { // user is scrolling
        self.textView.backgroundColor = [UIColor colorWithRed:0.898 green:0.898 blue:0.898 alpha:1]; //#E5E5E5, lighter gray
        self.button.backgroundColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1]; // #999999, button gray
        
        // button on left
        self.button.frame = CGRectMake(10, 10, 80, 20);
    }
    
    // setup text area exclusion path
    CGSize buttonSize = self.button.frame.size;
    buttonSize.height += 20; // can set button size like so, ...
    buttonSize.width += 20; // but not actually setting it just using calculation?
    CGFloat blockX = CGRectGetWidth(self.textView.bounds) - buttonSize.width;
    CGRect areaToBlockText = CGRectMake(blockX, 0, buttonSize.width, buttonSize.height);
    UIBezierPath* buttonPath = [UIBezierPath bezierPathWithRect:areaToBlockText];
    
    self.textView.textContainer.exclusionPaths = @[buttonPath];
}

// dismiss keyboard when stop composing
- (void) stopComposingComment {
    [self.textView resignFirstResponder];
}

#pragma mark - Setters & Getters

- (void) setIsWritingComment:(BOOL)isWritingComment {
    [self setIsWritingComment:isWritingComment animated:NO];
}

- (void) setIsWritingComment:(BOOL)isWritingComment animated:(BOOL)animated {
    _isWritingComment = isWritingComment;
    
    if (animated) {
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.3 initialSpringVelocity:1 options: UIViewAnimationOptionTransitionCrossDissolve
                         animations:^{
            [self layoutSubviews];
        } completion:nil];
    } else {
        [self layoutSubviews];
    }
}

// when text is set, update view to show text and enable user interaction
- (void) setText:(NSString*)text {
    _text = text;
    self.textView.text = text;
    self.textView.userInteractionEnabled = YES; // set to NO when uploading comment
    self.isWritingComment = text.length > 0; // based on if text is empty?
}

#pragma mark - Button Target

// when button pressed either bring up keyboard to type, or upload comment
- (void) commentButtonPressed:(UIButton*) sender {
    if (self.isWritingComment) { // user is done writing
        [self.textView resignFirstResponder];
        self.textView.userInteractionEnabled = NO;
        [self.delegate commentViewDidPressCommentButton:self];
    } else { // user wants to start writing
        [self setIsWritingComment:YES animated:YES];
        [self.textView becomeFirstResponder];
    }
}

#pragma mark - UITextViewDelegate

// delegate protocol informs delegate of user actions and updates isWritingComment
// could restrict user, but always return YES and allow user to do what they want

// similar to EndEditing
- (BOOL) textViewShouldBeginEditing:(UITextView*)textView {
    [self setIsWritingComment:YES animated:YES];
    [self.delegate commentViewWillStartEditing:self];
    
    return YES;
}

- (BOOL) textView:(UITextView*)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text {
    // first do the text replacement
    NSString* newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    [self.delegate commentView:self textDidChange:newText];
    return YES;
}

// similar to BeginEditing though isWriting set based on text length
- (BOOL) textViewShouldEndEditing:(UITextView*)textView {
    BOOL hasComment = textView.text.length > 0;
    [self setIsWritingComment:hasComment animated:YES];
    
    return YES;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
