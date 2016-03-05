//
//  CameraViewController.h
//  Blocstagram
//
//  Created by Jack Li on 3/5/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CameraViewController;

// will inform presenting VC when this camera VC is done
@protocol CameraViewControllerDelegate <NSObject>

- (void) cameraViewController:(CameraViewController*)cameraViewController didCompleteWithImage:(UIImage*)image;

@end

@interface CameraViewController : UIViewController

@property (nonatomic, weak) NSObject<CameraViewControllerDelegate>* delegate;

@end
