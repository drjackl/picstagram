//
//  MediaTableViewCell.m
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "MediaTableViewCell.h"
#import "User.h"
#import "Media.h"
#import "Comment.h"

@interface MediaTableViewCell () <UIGestureRecognizerDelegate> // to recognize tap

@property (nonatomic) UIImageView* mediaImageView;
@property (nonatomic) UILabel* usernameAndCaptionLabel;
@property (nonatomic) UILabel* commentLabel;

// auto-layout: create properties just for ones you'll change later
@property (nonatomic) NSLayoutConstraint* imageHeightConstraint;
@property (nonatomic) NSLayoutConstraint* usernameAndCaptionLabelHeightConstraint;
@property (nonatomic) NSLayoutConstraint* commentLabelHeightConstraint;

// for tap image fullscreens it
@property (nonatomic) UITapGestureRecognizer* tapGestureRecognizer;
@property (nonatomic) UILongPressGestureRecognizer* longPressGestureRecognizer;

// two finger tap retries an image download
@property (nonatomic) UITapGestureRecognizer* twoFingerTapGestureRecognizer;

@end

// static means will belong to every instance of this class
static UIFont* lightFont; // comments and captions
static UIFont* boldFont; // usernames
static UIColor* usernameLabelGray; // bkgd
static UIColor* commentLabelGray; // bkgd
static UIColor* linkColor; // username text color
static NSParagraphStyle* paragraphStyle; // line spacing, text alignment, ¶ spacing

static UIColor* firstCommentColor;
static NSMutableParagraphStyle* rightalignedParagraphStyle;

@implementation MediaTableViewCell

// "fakes" layout event to get full height
+ (CGFloat) heightForMediaItem:(Media*)mediaItem width:(CGFloat)width {
    MediaTableViewCell* layoutCell = [[MediaTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"layoutCell"]; // create cell
    layoutCell.mediaItem = mediaItem; // set mediaItem
    
//    // for manual layout
//    layoutCell.frame = CGRectMake(0, 0, width, CGFLOAT_MAX); // set width and tallest possible
//    [layoutCell layoutSubviews]; // make it adjust image view and labels
    
    // auto-layout
    layoutCell.frame = CGRectMake(0, 0, width, CGRectGetHeight(layoutCell.frame));
    [layoutCell setNeedsLayout];
    [layoutCell layoutIfNeeded];
    
    // height will be bottom of comments label
    return CGRectGetMaxY(layoutCell.commentLabel.frame);
}

// special method all objects have called only once before first class use
+ (void) load { // good place to initialize static vars
    lightFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:11];
    boldFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:11];
    usernameLabelGray = [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1]; // #EEEEEE
    commentLabelGray = [UIColor colorWithRed:0.898 green:0.898 blue:0.898 alpha:1]; // #E5E5E5
    linkColor = [UIColor colorWithRed:0.345 green:0.314 blue:0.427 alpha:1]; // #58506D
    
    NSMutableParagraphStyle* mutableParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    mutableParagraphStyle.headIndent = 20.0;
    mutableParagraphStyle.firstLineHeadIndent = 20.0;
    mutableParagraphStyle.tailIndent = -20.0; // end of line stops 20 points before right-most edge (if positive, from left-most edge)
    mutableParagraphStyle.paragraphSpacingBefore = 5; // distance between paragraphs
    
    paragraphStyle = mutableParagraphStyle; // all lines indented by 20 points
    
    firstCommentColor = [UIColor colorWithRed:255/255.0 green:127/255.0 blue:0 alpha:1]; // #FF7F00
    
    rightalignedParagraphStyle = [paragraphStyle mutableCopy];
    rightalignedParagraphStyle.alignment = NSTextAlignmentRight;
}

// override designated initializer
- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // initialization code
        self.mediaImageView = [[UIImageView alloc] init];
        
        // extra setup for adding tap image fullscreens it
        self.mediaImageView.userInteractionEnabled = YES;
        
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFired:)];
        self.tapGestureRecognizer.delegate = self;
        [self.mediaImageView addGestureRecognizer:self.tapGestureRecognizer];
        
        self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressFired:)]; // for sharing
        self.longPressGestureRecognizer.delegate = self;
        [self.mediaImageView addGestureRecognizer:self.longPressGestureRecognizer];
        
        // two finger tap retries downloading image
        self.twoFingerTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerTapFired:)];
        self.twoFingerTapGestureRecognizer.numberOfTouchesRequired = 2;
        self.twoFingerTapGestureRecognizer.delegate = self;
        [self.mediaImageView addGestureRecognizer:self.twoFingerTapGestureRecognizer];
        
        
        // initialization code continued
        self.usernameAndCaptionLabel = [[UILabel alloc] init];
        self.usernameAndCaptionLabel.numberOfLines = 0;
        self.usernameAndCaptionLabel.backgroundColor = usernameLabelGray;
        
        self.commentLabel = [[UILabel alloc] init];
        self.commentLabel.numberOfLines = 0;
        self.commentLabel.backgroundColor = commentLabelGray;
        
        for (UIView* view in @[self.mediaImageView, self.usernameAndCaptionLabel, self.commentLabel]) {
            [self.contentView addSubview:view];
            
            // for auto-layout needs to be set to NO
            view.translatesAutoresizingMaskIntoConstraints = NO;
        }
        
        // auto-layout: add some constraints
        NSDictionary* viewDictionary = NSDictionaryOfVariableBindings(_mediaImageView, _usernameAndCaptionLabel, _commentLabel);
        
        // visual format begins with H: or V:
        // | is superview, [viewVariable] represents one view
        // 3 constraints: view's leading/trailing edges equal to content view's
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_mediaImageView]|" options:kNilOptions metrics:nil views:viewDictionary]]; // [_mediaImageView(100)] to constrain width to 100
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_usernameAndCaptionLabel]|" options:kNilOptions metrics:nil views:viewDictionary]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_commentLabel]|" options:kNilOptions metrics:nil views:viewDictionary]];
        
        // stack 3 views vertically, no space in between
        // a single | at end caused constraints to not satisfy!
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_mediaImageView][_usernameAndCaptionLabel][_commentLabel]" options:kNilOptions metrics:nil views:viewDictionary]];
        
        // auto-layout height constraints; each has same arguments except the view item
        // view's initial height of 100 points will be update after content set
        // identifier optional, but easier for debugging
        self.imageHeightConstraint = [NSLayoutConstraint
                                      constraintWithItem:_mediaImageView
                                      attribute:NSLayoutAttributeHeight
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:nil
                                      attribute:NSLayoutAttributeNotAnAttribute
                                      multiplier:1
                                      constant:100];
        self.imageHeightConstraint.identifier = @"Image height constraint";
        self.usernameAndCaptionLabelHeightConstraint = [NSLayoutConstraint
                                                        constraintWithItem:_usernameAndCaptionLabel
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1
                                                        constant:100];
        self.usernameAndCaptionLabelHeightConstraint.identifier = @"Username and caption label height constraint";
        
        // read as: _commentLabel's height is equal to (nothing*1)+100
        // "nothing" could've been another item's attribute (eg a button's height)
        self.commentLabelHeightConstraint = [NSLayoutConstraint
                                             constraintWithItem:_commentLabel
                                             attribute:NSLayoutAttributeHeight
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:nil
                                             attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1
                                             constant:100];
        self.commentLabelHeightConstraint.identifier = @"Comment label height constraint";
        
        [self.contentView addConstraints:@[self.imageHeightConstraint, self.usernameAndCaptionLabelHeightConstraint, self.commentLabelHeightConstraint]];
    }
    return self;
}

// only used when building from storyboard
//- (void)awakeFromNib {
//    // Initialization code
//}

// just like subclassing UIView, also need to implement this method
// layout: place image, then place username and caption, then place comments
- (void) layoutSubviews {
    [super layoutSubviews];
    
    if (!self.mediaItem) { // verify mediaItem has been set
        return;
    }
    
//    // manual layout
//    // reuse proportion calculations in ImagesTableVC tableView:heightForRowIndex
//    CGFloat imageHeight = self.mediaItem.image.size.height * (CGRectGetWidth(self.contentView.bounds) / self.mediaItem.image.size.width);
//    self.mediaImageView.frame = CGRectMake(0, 0, CGRectGetWidth(self.contentView.bounds), imageHeight);
//    
//    // interesting computing sizes is really just for the height
//    CGSize sizeOfUsernameAndCaptionLabel = [self sizeOfString:self.usernameAndCaptionLabel.attributedText];
//    self.usernameAndCaptionLabel.frame = CGRectMake(0, CGRectGetMaxY(self.mediaImageView.frame), CGRectGetWidth(self.contentView.bounds), sizeOfUsernameAndCaptionLabel.height);
//    
//    CGSize sizeOfCommentLabel = [self sizeOfString:self.commentLabel.attributedText];
//    self.commentLabel.frame = CGRectMake(0, CGRectGetMaxY(self.usernameAndCaptionLabel.frame), CGRectGetWidth(self.bounds), sizeOfCommentLabel.height); // interesting width is from self.bounds here

    // auto-layout
    // before layout, calculate intrinsic label ("pack") size so can add padding
    CGSize maxSize = CGSizeMake(CGRectGetWidth(self.bounds), CGFLOAT_MAX);
    CGSize usernameLabelSize = [self.usernameAndCaptionLabel sizeThatFits:maxSize];
    CGSize commentLabelSize = [self.commentLabel sizeThatFits:maxSize];
    
    // overwrite previous 100 value (will need to be updated if used for delete)
    //self.usernameAndCaptionLabelHeightConstraint.constant = usernameLabelSize.height + 20;
    //self.commentLabelHeightConstraint.constant = commentLabelSize.height + 20;
    //self.imageHeightConstraint.constant = self.mediaItem.image.size.height * (CGRectGetWidth(self.contentView.bounds) / self.mediaItem.image.size.width); // comment out to constrain height to 100

    // when you delete items, need to check if the heights are zero, especially the last one cuz may divide by zero
    self.usernameAndCaptionLabelHeightConstraint.constant = usernameLabelSize.height == 0 ? 0 : usernameLabelSize.height + 20;
    self.commentLabelHeightConstraint.constant = commentLabelSize.height == 0 ? 0 : commentLabelSize.height + 20;
    if (self.mediaItem.image.size.width > 0 &&
        CGRectGetWidth(self.contentView.bounds) > 0) {
        self.imageHeightConstraint.constant = self.mediaItem.image.size.height * (CGRectGetWidth(self.contentView.bounds) / self.mediaItem.image.size.width);
    } else {
        self.imageHeightConstraint.constant = 0;
    }
    
    // hide line between cells
    self.separatorInset = UIEdgeInsetsMake(0, // top
                                           CGRectGetWidth(self.bounds)/2.0, // left
                                           0, // bottom
                                           CGRectGetWidth(self.bounds)/2.0); // right
    
}

#pragma mark - Image View

// target method of tap gesture
- (void) tapFired:(UITapGestureRecognizer*)sender { // interesting sender not used
    [self.delegate cell:self didTapImageView:self.mediaImageView];
}

- (void) longPressFired:(UILongPressGestureRecognizer*)sender {
    // if we don't check, this delegate method is called twice
    if (sender.state == UIGestureRecognizerStateBegan) { // Recognized is finger lift
        [self.delegate cell:self didLongPressImageView:self.mediaImageView];
    }
}

- (void) twoFingerTapFired:(UITapGestureRecognizer*)sender {
    [self.delegate cell:self didTwoFingerTapImageView:self.mediaImageView];
}

#pragma mark - UIGesturedRecognizerDelegate

// make sure zoom in doesn't happen while trying to delete (zoom only in non-edit mode)
- (BOOL) gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch {
    return self.isEditing == NO;
}

#pragma mark - UITableViewCell methods (cosmetic)

// rids ugly gray background
- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:NO animated:animated]; // disables standard gray selection
}

// rids ugly gray background
- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
    //[super setSelected:selected animated:animated]; // xcode boilerplate
    [super setSelected:NO animated:animated]; // disables background gray selection

    // Configure the view for the selected state
}

#pragma mark - Overriden setter method

// override auto-generated property setter
// update image and text labels whenever new media item is set
- (void) setMediaItem:(Media*)mediaItem {
    _mediaItem = mediaItem; // must use ivar when overriding a setter/getter, else 8loop
    // self.mediaItem = mediaItem; // causes infinite recursion since invoking self
    self.mediaImageView.image = _mediaItem.image;
    self.usernameAndCaptionLabel.attributedText = [self usernameAndCaptionAttributedString];
    self.commentLabel.attributedText = [self commentAttributedString];
}

#pragma mark - Attributed String

// create our first attributed string
- (NSAttributedString*) usernameAndCaptionAttributedString {
    CGFloat usernameFontSize = 15; // consistent size for both uname and caption
    
    // "username caption"
    NSString* baseString = [NSString stringWithFormat:@"%@ %@", self.mediaItem.user.userName, self.mediaItem.caption];
    
    // create attributed string with font and paragraph style
    NSMutableAttributedString* mutableUsernameAndCaptionString = // must be mutable
        [[NSMutableAttributedString alloc] initWithString:baseString
                                               attributes:@{NSFontAttributeName : [lightFont fontWithSize:usernameFontSize],
                                                            NSParagraphStyleAttributeName : paragraphStyle}];
    
    // bold and purple the username
    NSRange usernameRange = [baseString rangeOfString:self.mediaItem.user.userName];
    [mutableUsernameAndCaptionString addAttribute:NSFontAttributeName value:[boldFont fontWithSize:usernameFontSize] range:usernameRange];
    [mutableUsernameAndCaptionString addAttribute:NSForegroundColorAttributeName value:linkColor range:usernameRange];
    
    // increase kerning of caption
    [mutableUsernameAndCaptionString addAttribute:NSKernAttributeName value:@1 range:[baseString rangeOfString:self.mediaItem.caption]];
    
    return mutableUsernameAndCaptionString;
}

- (NSAttributedString*) commentAttributedString {
    NSMutableAttributedString* commentString = [[NSMutableAttributedString alloc] init];
    
    // "username comment" followed by a line break
//    for (Comment* comment in self.mediaItem.comments) {
    [self.mediaItem.comments enumerateObjectsUsingBlock:^(Comment* comment, NSUInteger i, BOOL * _Nonnull stop) { // using block to grab index to find first comment
        // "username comment<newline>"
        NSString* baseString = [NSString stringWithFormat:@"%@ %@\n", comment.from.userName, comment.text];
        
        // create attributed string
        NSMutableAttributedString* oneCommentString = [[NSMutableAttributedString alloc] initWithString:baseString attributes:@{NSFontAttributeName : lightFont}];//, NSParagraphStyleAttributeName : paragraphStyle}];
//        if (i % 2 == 1) { // right-align every other comment with initialization
//            oneCommentString = [[NSMutableAttributedString alloc] initWithString:baseString attributes:@{NSFontAttributeName : lightFont, NSParagraphStyleAttributeName : rightalignedParagraphStyle}];
//        }
        if (i % 2 == 0) {
            [oneCommentString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:[baseString rangeOfString:baseString]];
        } else { // right-align every other comment
            [oneCommentString addAttribute:NSParagraphStyleAttributeName value:rightalignedParagraphStyle range:[baseString rangeOfString:baseString]];
        }

        if (i == 0) { // if first comment, set to orange
            [oneCommentString addAttribute:NSForegroundColorAttributeName value:firstCommentColor range:[baseString rangeOfString:baseString]]; // is there a better way to specify an all range?
        }
        
        // bold and purple the username
        NSRange usernameRange = [baseString rangeOfString:comment.from.userName];
        [oneCommentString addAttribute:NSFontAttributeName value:boldFont range:usernameRange];
        [oneCommentString addAttribute:NSForegroundColorAttributeName value:linkColor range:usernameRange];
        
        // append comment
        [commentString appendAttributedString:oneCommentString];
//    } // end for
    }]; // end block

    
    return commentString;
}

#pragma mark - Layout Size Calculations

// calculates how tall our labels need to be (for manual or frame-based layout)
- (CGSize) sizeOfString:(NSAttributedString*)string {
    CGSize maxSize = CGSizeMake(CGRectGetWidth(self.contentView.bounds) - 40, 0.0);
    CGRect sizeRect = [string boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin context:nil]; // find string space requirements
    sizeRect.size.height += 20; // top and bottom padding for breathing room
    sizeRect = CGRectIntegral(sizeRect); // round off to integral values
    return sizeRect.size;
}

@end
