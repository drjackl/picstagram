//
//  FilterCollectionViewCell.m
//  Blocstagram
//
//  Created by Jack Li on 3/6/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "FilterCollectionViewCell.h"

@interface FilterCollectionViewCell ()

@property (nonatomic) UIImageView* thumbnail;
@property (nonatomic) UILabel* label;

@end

static UIFont* labelFont;


@implementation FilterCollectionViewCell

+ (void) load {
    labelFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:10];
}

// init method never gets called! must call initWithFrame:

// use ViewCell's initWithFrame: to initialize, though subviews don't need that
- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.thumbnail = [[UIImageView alloc] init];
        self.thumbnail.clipsToBounds = YES;
        
        self.label = [[UILabel alloc] init];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.font = labelFont;
        
        [self.contentView addSubview:self.thumbnail];
        [self.contentView addSubview:self.label];
        
        //self.thumbnail.translatesAutoresizingMaskIntoConstraints = NO;
        //self.label.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (instancetype) initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        NSLog(@"initCoder called");
    }
    return self;
}

- (void) layoutSubviews {
    NSLog(@"content view bounds: %@", NSStringFromCGRect(self.contentView.bounds));
    
    if (!self.thumbnail || !self.title) {
        return;
    }
    
    CGFloat width = CGRectGetHeight(self.contentView.bounds) - 20;
    NSLog(@"get height: %f", CGRectGetHeight(self.contentView.bounds));
    NSLog(@"width: %f", width);
    
    self.thumbnail.frame = CGRectMake(0, 0, width, width);
    self.label.frame = CGRectMake(0, width, width, 20);
    
//    self.thumbnail.frame = CGRectMake(10, 10, 80, 20);
//    self.label.frame = CGRectMake(10, 10, 80, 20);
    
    NSLog(@"thumbnail: %@", NSStringFromCGRect(self.thumbnail.frame));
    NSLog(@"label: %@", NSStringFromCGRect(self.label.frame));
}

- (void) setTitle:(NSString*)title {
    _title = title;
    self.label.text = _title;
}

- (void) setImage:(UIImage*)image {
    _image = image;
    self.thumbnail.image = _image;
}

@end
