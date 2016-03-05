//
//  CameraToolbar.h
//  Blocstagram
//
//  Created by Jack Li on 3/4/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CameraToolbar;

@protocol CameraToolbarDelegate <NSObject>

- (void) leftButtonPressedOnToolbar:(CameraToolbar*)toolbar;
- (void) rightButtonPressedOnToolbar:(CameraToolbar*)toolbar;
- (void) cameraButtonPressedOnToolbar:(CameraToolbar*)toolbar;

@end

@interface CameraToolbar : UIView

// image names passed into init (3)
- (instancetype) initWithImageNames:(NSArray*)imageNames;

@property (nonatomic, weak) NSObject<CameraToolbarDelegate>* delegate;

@end
