//
//  CropImageViewController.h
//  Blocstagram
//
//  Created by Jack Li on 3/5/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "MediaFullScreenViewController.h"

@class CropImageViewController;

// another controller will pass it a UIImage and set itself as crop controller's dg
@protocol CropImageViewControllerDelegate <NSObject>

// user will size and crop image, and controller will pass new cropped image back to its delegate
- (void) cropControllerFinishedWithImage:(UIImage*)croppedImage;

@end


@interface CropImageViewController : MediaFullScreenViewController

- (instancetype) initWithImage:(UIImage*)sourceImage;

@property (nonatomic, weak) NSObject<CropImageViewControllerDelegate>* delegate;

@end
