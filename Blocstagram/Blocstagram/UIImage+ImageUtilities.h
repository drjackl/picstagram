//
//  UIImage+ImageUtilities.h
//  Blocstagram
//
//  Created by Jack Li on 3/5/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ImageUtilities)

- (UIImage*) imageWithFixedOrientation;
- (UIImage*) imageResizedToMatchAspectRationOfSize:(CGSize)size;
- (UIImage*) imageCroppedToRect:(CGRect)cropRect;

@end
