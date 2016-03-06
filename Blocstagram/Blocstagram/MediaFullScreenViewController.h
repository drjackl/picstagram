//
//  MediaFullScreenViewController.h
//  Blocstagram
//
//  Created by Jack Li on 3/2/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Media; // forward declare Media below

@interface MediaFullScreenViewController : UIViewController

@property (nonatomic) UIScrollView* scrollView;
@property (nonatomic) UIImageView* imageView;

// moved out of extension for photos to prep for being subclassed
@property (nonatomic) Media* media;


- (instancetype) initWithMedia:(Media*)media; // like past custom initialzers

- (void) centerScrollView; // explained later

- (void) recalculateZoomScale; // created to prep for being subclassed for photos

@end
